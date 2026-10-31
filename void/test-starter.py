"""Safety tests and actual X11 hotkey test. Requires build/X11 dependencies.
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
        self.assertEqual(sorted(p.name for p in data.iterdir()),['config','dwm','monitors.sh','power-action.sh','power-menu','status.sh','wallpaper.sh','xinitrc'])
    def test_symlink_destination_refused(self):
        (self.home/'.local/share').mkdir(parents=True)
        outside=self.base/'outside';outside.mkdir()
        (self.home/'.local/share/dwm-void').symlink_to(outside,target_is_directory=True)
        self.assertNotEqual(self.install().returncode,0)
        self.assertEqual(list(outside.iterdir()),[])
    def test_independent_nine_workspaces_and_status_on_two_monitors(self):
        result=self.install();self.assertEqual(result.returncode,0,result.stderr)
        shim=self.base/'screens.c'
        shim.write_text('''#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/extensions/Xinerama.h>
Bool XineramaIsActive(Display *d) { return True; }
XineramaScreenInfo *XineramaQueryScreens(Display *d, int *n) {
    XineramaScreenInfo *s=calloc(2,sizeof(*s)); *n=2;
    s[0]=(XineramaScreenInfo){0,0,0,2560,1080};
    s[1]=(XineramaScreenInfo){1,2560,0,1920,1080}; return s;
}
''')
        library=self.base/'screens.so'
        subprocess.run(['cc','-shared','-fPIC',str(shim),'-o',str(library)],check=True)
        env={**self.env,'DISPLAY':':196'}
        log=open(self.base/'dual.log','w')
        server=subprocess.Popen(['Xvfb',':196','-screen','0','4480x1080x24','-nolisten','tcp'],stdout=log,stderr=log)
        wm=None; terminals=[]
        def command(*args):
            return subprocess.run(args,env=env,capture_output=True,text=True,check=True).stdout
        def geometry(win):
            return dict(line.split('=',1) for line in command('xdotool','getwindowgeometry','--shell',win).splitlines() if '=' in line)
        try:
            for _ in range(100):
                if subprocess.run(['xprop','-root'],env=env,capture_output=True).returncode==0:break
                time.sleep(.05)
            wm=subprocess.Popen([str(self.home/'.local/share/dwm-void/dwm')],env={**env,'LD_PRELOAD':str(library)},stdout=log,stderr=log)
            time.sleep(.6)
            bars=command('xdotool','search','--onlyvisible','--class','^dwm$').split()
            self.assertEqual(len(bars),2)
            self.assertEqual(sorted(int(geometry(b)['WIDTH']) for b in bars),[1920,2560])
            for label,pos in [('LeftTest','100'),('RightTest','3000')]:
                command('xdotool','mousemove',pos,'300'); time.sleep(.15)
                terminals.append(subprocess.Popen(['xterm','-class',label],env=env,stdout=log,stderr=log))
                time.sleep(.3)
            left=command('xdotool','search','--class','LeftTest').split()[0]
            right=command('xdotool','search','--class','RightTest').split()[0]
            for origin,win,other,otherx in [(0,left,right,2560),(2560,right,left,0)]:
                command('xdotool','mousemove',str(origin+38),'8');command('xdotool','click','1');time.sleep(.2)
                self.assertLess(int(geometry(win)['X']),0)
                self.assertEqual(int(geometry(other)['X']),otherx)
                command('xdotool','mousemove',str(origin+12),'8');command('xdotool','click','1');time.sleep(.2)
                self.assertEqual(int(geometry(win)['X']),origin)
            helper=self.home/'.local/share/dwm-void/power-action.sh'
            helper.write_text('#!/bin/sh\nprintf "%s" "$1" > "$HOME/power-invocation"\n')
            command('xdotool','mousemove','4470','8');command('xdotool','click','1');time.sleep(.3)
            menu=command('xdotool','search','--name','^Void Power$').split()[0]
            command('xdotool','mousemove','--window',menu,'30','67');command('xdotool','click','1');time.sleep(.2)
            self.assertFalse((self.home/'power-invocation').exists())
            capture=os.environ.get('VOID_TEST_POWER_CAPTURE')
            if capture:command('import','-window',menu,capture)
            command('xdotool','key','Escape');time.sleep(.2)
            self.assertFalse((self.home/'power-invocation').exists())
            command('xdotool','mousemove','4470','8');command('xdotool','click','1');time.sleep(.3)
            menu=command('xdotool','search','--name','^Void Power$').split()[0]
            command('xdotool','mousemove','--window',menu,'30','67');command('xdotool','click','1');time.sleep(.2)
            command('xdotool','mousemove','--window',menu,'30','151');command('xdotool','click','1');time.sleep(.3)
            self.assertEqual((self.home/'power-invocation').read_text(),'reboot')
            for tag in range(2,10):
                command('xdotool','mousemove','3000','300');command('xdotool','key',f'super+{tag}');time.sleep(.1)
                self.assertEqual(int(geometry(left)['X']),0)
                self.assertLess(int(geometry(right)['X']),0)
                command('xdotool','key','super+1');time.sleep(.1)
                self.assertEqual(int(geometry(right)['X']),2560)
            for tag in range(2,10):
                command('xdotool','mousemove','100','300');command('xdotool','key',f'super+{tag}');time.sleep(.1)
                self.assertLess(int(geometry(left)['X']),0)
                self.assertEqual(int(geometry(right)['X']),2560)
                command('xdotool','key','super+1');time.sleep(.1)
            command('xsetroot','-name','');time.sleep(.15)
            for i,b in enumerate(bars):command('import','-window',b,str(self.base/f'before{i}.png'))
            command('xsetroot','-name','31.10.2026 17:46');time.sleep(.2)
            for i,b in enumerate(bars):
                path=self.base/f'after{i}.png';command('import','-window',b,str(path))
                self.assertNotEqual(path.read_bytes(),(self.base/f'before{i}.png').read_bytes())
                capture=os.environ.get('VOID_TEST_DUAL_CAPTURE')
                if capture:shutil.copy(path,f'{capture}-{geometry(b)["WIDTH"]}.png')
            print('Verified: workspace mouse clicks on both monitors; menu opens, Escape cancels, confirmation invokes stub only; 1-9 independent; both statuses update. Physical Void hardware remains unverified.')
        finally:
            for terminal in terminals:
                if terminal.poll() is None:terminal.terminate();terminal.wait(timeout=5)
            if wm and wm.poll() is None:wm.terminate();wm.wait(timeout=5)
            server.terminate();server.wait(timeout=5);log.close()
    def test_super_x_launches_alacritty_and_quit_exits(self):
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
            print('Verified: native bar, status, Alacritty invocation with Xterm substitute, quit, no upstream hooks. Real Void hardware still unverified.')
        finally:
            if wm and wm.poll() is None:wm.terminate();wm.wait(timeout=10)
            subprocess.run(['pkill','-f',str(self.home)],capture_output=True)
            xvfb.terminate();xvfb.wait(timeout=10);log.close()
if __name__=='__main__': unittest.main()
