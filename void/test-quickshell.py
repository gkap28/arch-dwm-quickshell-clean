"""Real Quickshell/X11 flow; fake only Xinerama geometry and power actions."""
import importlib.util, os, pathlib, subprocess, time, unittest, re
source = pathlib.Path(__file__).with_name('test-starter.py')
spec = importlib.util.spec_from_file_location('starter', source)
starter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(starter)

class QuickshellTests(starter.StarterTests):
    def test_quickshell_workspace_and_fallback(self):
        single = os.environ.get('VOID_TEST_MODULES') == '1'
        result=self.install(); self.assertEqual(result.returncode,0,result.stderr)
        shim=self.base/'screens.c'
        shim.write_text('''#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/extensions/Xinerama.h>
Bool XineramaIsActive(Display *d) { return True; }
XineramaScreenInfo *XineramaQueryScreens(Display *d, int *n) {
XineramaScreenInfo *s=calloc(2,sizeof(*s)); *n=2;
s[0]=(XineramaScreenInfo){0,0,0,2560,1080}; s[1]=(XineramaScreenInfo){1,2560,0,1920,1080}; return s;
}''')
        library=self.base/'screens.so'
        flags=subprocess.run(['pkg-config','--cflags','x11','xinerama'],capture_output=True,text=True,check=True).stdout.split()
        subprocess.run(['cc','-shared','-fPIC',*flags,str(shim),'-o',str(library)],check=True)
        runtime=self.base/'runtime';runtime.mkdir(mode=0o700)
        env={**self.env,'DISPLAY':':198','XDG_RUNTIME_DIR':str(runtime),'QT_QUICK_BACKEND':'software','QT_QPA_PLATFORM':'xcb'}
        log=open(self.base/'quickshell.log','w')
        server=subprocess.Popen(['Xvfb',':198','-screen','0','1280x1080x24' if single else '4480x1080x24','-nolisten','tcp'],stdout=log,stderr=log)
        wm=None; panel=None; windows=[]
        def command(*args):return subprocess.run(args,env=env,capture_output=True,text=True,check=True).stdout
        def geometry(win):return dict(line.split('=',1) for line in command('xdotool','getwindowgeometry','--shell',win).splitlines() if '=' in line)
        try:
            for _ in range(100):
                if subprocess.run(['xprop','-root'],env=env,capture_output=True).returncode==0:break
                time.sleep(.05)
            data=self.home/'.local/share/dwm-void'
            wm=subprocess.Popen([str(data/'dwm')],env=env if single else {**env,'LD_PRELOAD':str(library)},stdout=log,stderr=log)
            time.sleep(1)
            panel=subprocess.Popen(['quickshell','--path',str(data/'quickshell/shell.qml')],env=env if single else {**env,'LD_PRELOAD':str(library)},stdout=log,stderr=log)
            bars=[]
            for _ in range(100):
                tree=command('xwininfo','-root','-tree')
                bars=re.findall(r'(0x[0-9a-f]+) "quickshell": .*?\d+x28\+',tree)
                if bars:break
                if panel.poll() is not None:break
                time.sleep(.1)
            self.assertTrue(bars,command('xwininfo','-root','-tree')+(self.base/'quickshell.log').read_text())
            self.assertIsNone(panel.poll(),(self.base/'quickshell.log').read_text())
            print('Quickshell bars:',[geometry(b) for b in bars])
            command('xsetroot','-name','31.10.2026 18:00')
            time.sleep(1.5)  # the bar window exists before it is mapped
            pathlib.Path('/tmp/void-bar-check').mkdir(exist_ok=True)
            for i,b in enumerate(bars):command('import','-window',b,f'/tmp/void-bar-check/quickshell-{i}.png')
            if not single:
                # XRandR in Xvfb reports a single logical Qt screen; monitor bridge still targets both dwm monitors.
                for origin,label in [(0,'QSLeft'),(2560,'QSRight')]:
                    command('xdotool','mousemove',str(origin+100),'300')
                    windows.append(subprocess.Popen(['xterm','-class',label],env=env,stdout=log,stderr=log));time.sleep(.4)
                left=command('xdotool','search','--class','QSLeft').split()[0]
                right=command('xdotool','search','--class','QSRight').split()[0]
                for origin,win,other in [(0,left,right),(2560,right,left)]:
                    before=geometry(other)['X']
                    command(str(data/'bar-bridge'),'view','1',str(origin),'0');time.sleep(.3)
                    self.assertLess(int(geometry(win)['X']),0)
                    self.assertEqual(geometry(other)['X'],before)
                    command(str(data/'bar-bridge'),'view','0',str(origin),'0');time.sleep(.3)
                    self.assertEqual(int(geometry(win)['X']),origin)
                # Exercise actual QML tag click, not only bridge.
                command('xdotool','mousemove','65','14');command('xdotool','click','1');time.sleep(.3)
                self.assertLess(int(geometry(left)['X']),0)
                self.assertEqual(int(geometry(right)['X']),2560)
                command('xdotool','mousemove','43','14');command('xdotool','click','1');time.sleep(.3)
                self.assertEqual(int(geometry(left)['X']),0)
            # Power from actual QML, no real system actions.
            (data/'power-action.sh').write_text('#!/bin/sh\nprintf "%s" "$1" > "$HOME/power-invocation"\n')
            width=int(geometry(bars[0])['WIDTH'])
            if single:
                # Real module clicks open the Nord popups; settings launch harmless stubs.
                for tool in ['pavucontrol','nm-connection-editor']:
                    script=self.bin/tool
                    script.write_text(f'#!/bin/sh\nprintf opened > "$HOME/{tool}-opened"\n');script.chmod(0o755)
                command('xdotool','mousemove',str(width-76),'14');command('xdotool','click','1');time.sleep(.4)
                popups=[win for win in re.findall(r'(0x[0-9a-f]+) "quickshell": .*?280x184\+',command('xwininfo','-root','-tree'))]
                self.assertTrue(popups,command('xwininfo','-root','-tree')+(self.base/'quickshell.log').read_text())
                command('import','-window',popups[0],'/tmp/void-bar-check/audio-module.png')
                command('xdotool','mousemove','--window',popups[0],'130','132');command('xdotool','click','1');time.sleep(.5)
                self.assertEqual((self.home/'pavucontrol-opened').read_text(),'opened')
                command('xdotool','mousemove',str(width-152),'14');command('xdotool','click','1');time.sleep(.4)
                popups=re.findall(r'(0x[0-9a-f]+) "quickshell": .*?280x144\+',command('xwininfo','-root','-tree'))
                self.assertTrue(popups,command('xwininfo','-root','-tree'))
                command('import','-window',popups[0],'/tmp/void-bar-check/network-module.png')
                command('xdotool','mousemove','--window',popups[0],'60','95');command('xdotool','click','1');time.sleep(.5)
                self.assertEqual((self.home/'nm-connection-editor-opened').read_text(),'opened')
            command('xdotool','mousemove',str(width-14),'14');command('xdotool','click','1');time.sleep(.4)
            menu=command('xdotool','search','--name','^Void Power$').split()[0]
            command('xdotool','key','Escape');time.sleep(.2)
            self.assertFalse((self.home/'power-invocation').exists())
            command('xdotool','mousemove','14','14');command('xdotool','click','1');time.sleep(.4)
            self.assertRegex(command('xwininfo','-root','-tree'),r'276x\d+\+6\+28 ','QML control center below the bar')
            # With client windows focused, dwm keeps the keyboard; a second logo click closes it.
            command('xdotool','mousemove','14','14');command('xdotool','click','1');time.sleep(.3)
            self.assertNotRegex(command('xwininfo','-root','-tree'),r'276x\d+\+6\+28 ','Logo click toggles the control center closed')
            applications=self.home/'.local/share/applications';applications.mkdir(parents=True)
            app=self.base/'launch-test';app.write_text('#!/bin/sh\nprintf launched > "$HOME/launched-app"\n');app.chmod(0o755)
            (applications/'void-launch-test.desktop').write_text(f'[Desktop Entry]\nType=Application\nName=Void Launcher Probe\nExec={app}\nTerminal=false\n')
            command('xdotool','mousemove','14','14');command('xdotool','click','1');time.sleep(.3)
            command('xdotool','mousemove','100','95');command('xdotool','click','1')  # "Programme" row
            launcher=[]
            for _ in range(100):
                found=subprocess.run(['xdotool','search','--onlyvisible','--name','^Void Applications$'],env=env,capture_output=True,text=True)
                if found.returncode==0:launcher=found.stdout.split();break
                time.sleep(.1)
            self.assertTrue(launcher,(self.base/'quickshell.log').read_text())
            self.assertEqual(int(geometry(launcher[0])['WIDTH']),820)
            self.assertEqual(int(geometry(launcher[0])['HEIGHT']),600)
            command('xdotool','windowactivate','--sync',launcher[0]);time.sleep(.3)
            command('xdotool','type','Void Launcher Probe');time.sleep(.5)
            command('import','-window',launcher[0],'/tmp/void-bar-check/launcher.png')
            command('xdotool','key','Return');time.sleep(.5)
            self.assertEqual((self.home/'launched-app').read_text(),'launched')
            panel.terminate();panel.wait(timeout=5);time.sleep(.5)
            native=[b for b in command('xdotool','search','--onlyvisible','--class','^dwm$').split() if int(geometry(b)['WIDTH'])>100]
            self.assertEqual(len(native),1 if single else 2,str([geometry(b) for b in native])+command('xwininfo','-root','-tree'))
            self.assertIsNone(wm.poll())
            print('Verified real Quickshell: Nord bar, QML workspace clicks, monitor-targeted bridge, power/control opening, native fallback. Physical Void/Qt dual outputs unverified.')
        finally:
            for p in windows+[panel,wm,server]:
                if p and p.poll() is None:p.terminate();p.wait(timeout=5)
            log.close()

if __name__=='__main__':unittest.main()