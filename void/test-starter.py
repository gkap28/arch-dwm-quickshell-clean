"""Safety tests and actual X11 hotkey test. Use the documented nix-shell below.
The installer OS gate is changed ONLY in an isolated test copy; host files untouched.
"""
import os, pathlib, shutil, subprocess, tempfile, time, unittest
ROOT = pathlib.Path(__file__).resolve().parents[1]
class StarterTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dwm-void-test-')
        self.base = pathlib.Path(self.temp.name)
        self.repo = self.base/'repo'
        self.repo.mkdir()
        for name in ['dwm.c','drw.c','drw.h','util.c','util.h','tomlparser.c','tomlparser.h','config.def.h','config.mk']:
            shutil.copy(ROOT/name, self.repo/name)
        shutil.copytree(ROOT/'void', self.repo/'void')
        s=(self.repo/'void/start.sh').read_text()
        s=s.replace('[ "$(id -u)" -ne 0 ]','[ 1000 -ne 0 ]')
        s=s.replace('[ -r /etc/os-release ]','[ -r "$VOID_TEST_OS" ]').replace('. /etc/os-release','. "$VOID_TEST_OS"')
        (self.repo/'void/start.sh').write_text(s)
        self.home=self.base/'home'; self.home.mkdir()
        self.bin=self.base/'bin'; self.bin.mkdir()
        for name in ['startx']:
            p=self.bin/name;p.write_text('#!/bin/sh\nexit 0\n');p.chmod(0o755)
        osfile=self.base/'os-release';osfile.write_text('ID=void\n')
        self.env={**os.environ,'HOME':str(self.home),'VOID_TEST_OS':str(osfile),'PATH':str(self.bin)+':'+os.environ['PATH']}
        self.env.pop('DISPLAY',None)
    def tearDown(self): self.temp.cleanup()
    def install(self, mode='--install'):
        return subprocess.run(['sh',str(self.repo/'void/start.sh'),mode],env=self.env,capture_output=True,text=True)
    def test_non_void_refused_without_writes(self):
        pathlib.Path(self.env['VOID_TEST_OS']).write_text('ID=arch\n')
        self.assertNotEqual(self.install().returncode,0)
        self.assertEqual(list(self.home.iterdir()),[])
    def test_existing_config_and_arch_sources_preserved(self):
        data=self.home/'.local/share/dwm-void';(data/'config').mkdir(parents=True)
        original=b'# keep my settings\n'
        (data/'config/hotkeys.toml').write_bytes(original)
        (self.home/'.config/quickshell').mkdir(parents=True)
        (self.home/'.config/quickshell/shell.qml').write_text('keep')
        (self.home/'.xinitrc').write_text('keep')
        before={p.name:p.read_bytes() for p in self.repo.iterdir() if p.is_file()}
        result=self.install();self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual((data/'config/hotkeys.toml').read_bytes(),original)
        self.assertEqual((self.home/'.xinitrc').read_text(),'keep')
        self.assertEqual((self.home/'.config/quickshell/shell.qml').read_text(),'keep')
        self.assertEqual(before,{p.name:p.read_bytes() for p in self.repo.iterdir() if p.is_file()})
        self.assertEqual(sorted(p.name for p in data.iterdir()),['config','dwm','monitors.sh','status.sh','xinitrc'])
    def test_symlink_destination_refused(self):
        (self.home/'.local/share').mkdir(parents=True)
        outside=self.base/'outside';outside.mkdir()
        (self.home/'.local/share/dwm-void').symlink_to(outside,target_is_directory=True)
        self.assertNotEqual(self.install().returncode,0)
        self.assertEqual(list(outside.iterdir()),[])
    def test_super_x_launches_alacritty_and_quit_exits(self):
        # Alacritty needs GL unavailable in this sandbox. A named test terminal
        # records the actual alacritty invocation and shows a real X11 window.
        result=self.install();self.assertEqual(result.returncode,0,result.stderr)
        terminal=self.bin/'alacritty'
        terminal.write_text('#!/bin/sh\nprintf alacritty > "$HOME/terminal-invocation"\nexec xterm -class Alacritty\n')
        terminal.chmod(0o755)
        display=':197'
        env={**self.env,'DISPLAY':display,'LIBGL_ALWAYS_SOFTWARE':'1'}
        drivers=list(pathlib.Path('/nix/store').glob('*mesa*/lib/dri/swrast_dri.so'))
        if drivers: env['LIBGL_DRIVERS_PATH']=str(drivers[0].parent)
        upstream=self.home/'.local/share/dwm-titus/scripts';upstream.mkdir(parents=True)
        for name in ['autostart.sh','autostop.sh','theme-apply.sh']:
            p=upstream/name;p.write_text('#!/bin/sh\ntouch "$HOME/unwanted-autostart"\n');p.chmod(0o755)
        log=open(self.base/'runtime.log','w')
        xvfb=subprocess.Popen(['Xvfb',display,'-screen','0','1280x800x24','-nolisten','tcp'],stdout=log,stderr=log)
        wm=None
        try:
            for _ in range(100):
                if subprocess.run(['xprop','-root'],env=env,capture_output=True).returncode==0:break
                time.sleep(.05)
            wm=subprocess.Popen([str(self.home/'.local/share/dwm-void/dwm')],env=env,stdout=log,stderr=log)
            for _ in range(100):
                if b'dwm' in subprocess.run(['xprop','-root','_NET_SUPPORTING_WM_CHECK'],env=env,capture_output=True).stdout: break
                # wait by property type; root ID doesn't contain 'dwm'
                if b'window id' in subprocess.run(['xprop','-root','_NET_SUPPORTING_WM_CHECK'],env=env,capture_output=True).stdout:break
                time.sleep(.05)
            self.assertIsNone(wm.poll())
            bars=[]
            for _ in range(100):
                found=subprocess.run(['xdotool','search','--onlyvisible','--class','^dwm$'],env=env,capture_output=True,text=True)
                if found.returncode==0:bars=found.stdout.split();break
                time.sleep(.05)
            self.assertEqual(len(bars),1,(self.base/'runtime.log').read_text())
            bar_geometry=subprocess.run(['xdotool','getwindowgeometry','--shell',bars[0]],env=env,capture_output=True,text=True,check=True).stdout
            bar_values=dict(line.split('=',1) for line in bar_geometry.splitlines() if '=' in line)
            self.assertGreater(int(bar_values['HEIGHT']),0)
            self.assertEqual(int(bar_values['Y']),0)
            self.assertEqual(int(bar_values['WIDTH']),1280)
            subprocess.run(['xsetroot','-name','Void bar test 12:34'],env=env,check=True)
            time.sleep(.2)
            self.assertIsNone(wm.poll(),(self.base/'runtime.log').read_text())
            self.assertIn('Void bar test 12:34',subprocess.run(['xprop','-root','WM_NAME'],env=env,capture_output=True,text=True).stdout)
            capture=os.environ.get('VOID_TEST_BAR_CAPTURE')
            if capture:subprocess.run(['import','-window',bars[0],capture],env=env,check=True)
            subprocess.run(['xdotool','key','super+x'],env=env,check=True)
            windows=[]
            for _ in range(120):
                found=subprocess.run(['xdotool','search','--onlyvisible','--class','Alacritty'],env=env,capture_output=True,text=True)
                if found.returncode==0:windows=found.stdout.split();break
                time.sleep(.1)
            self.assertTrue(windows,(self.base/'runtime.log').read_text())
            self.assertEqual((self.home/'terminal-invocation').read_text(),'alacritty')
            geometry=subprocess.run(['xwininfo','-id',windows[0]],env=env,capture_output=True,text=True).stdout
            self.assertIn('Width: 1280',geometry)
            self.assertFalse((self.home/'unwanted-autostart').exists())
            subprocess.run(['xdotool','key','super+shift+q'],env=env,check=True)
            wm.wait(timeout=10);self.assertEqual(wm.returncode,0)
            self.assertFalse((self.home/'unwanted-autostart').exists())
            print('Verified: native bar visible at top with positive height; status update; Super+X invokes alacritty command; Xterm substitute visible and tiled; quit; no upstream hooks. Real Void hardware still unverified.')
        finally:
            if wm and wm.poll() is None:wm.terminate();wm.wait(timeout=10)
            subprocess.run(['pkill','-f',str(self.home)],capture_output=True)
            xvfb.terminate();xvfb.wait(timeout=10);log.close()
if __name__=='__main__': unittest.main()
