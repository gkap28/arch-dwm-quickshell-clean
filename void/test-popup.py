"""X11 popup regression. Requires same dependencies as test-starter.py.
Uses isolated home and harmless action stubs; no real power action.
"""
import os, pathlib, runpy, subprocess, time, unittest
Base=runpy.run_path(str(pathlib.Path(__file__).with_name('test-starter.py')))['StarterTests']
class PopupTest(unittest.TestCase):
    def test_held_mouse_and_control_on_each_monitor(self):
        fixture=Base(); fixture.setUp()
        env={**fixture.env,'DISPLAY':':195'}
        server=None; wm=None
        def cmd(*args):return subprocess.run(args,env=env,capture_output=True,text=True,check=True).stdout
        try:
            result=fixture.install();self.assertEqual(result.returncode,0,result.stderr)
            shim=fixture.base/'screens.c';shim.write_text('''#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/extensions/Xinerama.h>
Bool XineramaIsActive(Display *d){return True;}
XineramaScreenInfo *XineramaQueryScreens(Display *d,int *n){*n=2;XineramaScreenInfo *s=calloc(2,sizeof(*s));s[0]=(XineramaScreenInfo){0,0,0,2560,1080};s[1]=(XineramaScreenInfo){1,2560,0,1920,1080};return s;}
''')
            lib=fixture.base/'screens.so';subprocess.run(['cc','-shared','-fPIC',str(shim),'-o',str(lib)],check=True)
            server=subprocess.Popen(['Xvfb',':195','-screen','0','4480x1080x24','-nolisten','tcp'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
            time.sleep(.5)
            data=fixture.home/'.local/share/dwm-void'
            for helper in ['control-action.sh','power-action.sh']:
                (data/helper).write_text('#!/bin/sh\nprintf "%s" "$1" > "$HOME/invocation"\n')
            wm=subprocess.Popen([str(data/'dwm')],env={**env,'LD_PRELOAD':str(lib)},stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);time.sleep(.5)
            cmd('xdotool','mousemove','4470','8');cmd('xdotool','mousedown','1');time.sleep(.5);cmd('xdotool','mouseup','1');time.sleep(.3)
            power=cmd('xdotool','search','--onlyvisible','--name','^Void Power$').split()[0]
            self.assertFalse((fixture.home/'invocation').exists())
            cmd('xdotool','key','Escape');time.sleep(.2)
            for origin in [0,2560]:
                cmd('xdotool','mousemove',str(origin+8),'8');cmd('xdotool','mousedown','1');time.sleep(.5);cmd('xdotool','mouseup','1');time.sleep(.3)
                center=cmd('xdotool','search','--onlyvisible','--name','^Void Control$').split()[0]
                geo=dict(line.split('=',1) for line in cmd('xdotool','getwindowgeometry','--shell',center).splitlines() if '=' in line)
                self.assertEqual(int(geo['X']),origin+10)
                cmd('xdotool','mousemove','--window',center,'30','151');cmd('xdotool','click','1');time.sleep(.3)
                self.assertEqual((fixture.home/'invocation').read_text(),'hotkeys')
                (fixture.home/'invocation').unlink()
        finally:
            if wm and wm.poll() is None:wm.terminate();wm.wait(timeout=5)
            if server and server.poll() is None:server.terminate();server.wait(timeout=5)
            fixture.tearDown()
if __name__=='__main__':unittest.main()
