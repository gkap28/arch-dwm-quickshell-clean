"""Real installed private dwm + Quickshell, without compositor or system actions.
Run with VOID_TEST_SOURCE_ROOT pointing to the complete delivered repository.
"""
import importlib.util, os, pathlib, re, subprocess, time, unittest

spec = importlib.util.spec_from_file_location('starter', pathlib.Path(__file__).with_name('test-starter.py'))
starter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(starter)
starter.ROOT = pathlib.Path(os.environ.get('VOID_TEST_SOURCE_ROOT', starter.ROOT))

class WindowIntegrationTests(starter.StarterTests):
    def test_launcher_stays_windowed_and_panels_survive(self):
        terminal = self.bin/'alacritty'
        terminal.write_text('#!/bin/sh\nexit 0\n'); terminal.chmod(0o755)
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stderr)
        data = self.home / '.local/share/dwm-void'
        (data/'updates.sh').write_text('#!/bin/sh\nif [ "$1" = status ]; then printf "2\\t3\\n"; else printf "%s\\n" "$1" >> "$HOME/actions"; fi\n')
        (data/'power-action.sh').write_text('#!/bin/sh\nprintf "%s\\n" "$1" >> "$HOME/actions"\n')
        apps = self.home/'.local/share/applications'; apps.mkdir(parents=True)
        probe = self.base/'probe'; probe.write_text('#!/bin/sh\nprintf launched > "$HOME/launched"\n'); probe.chmod(0o755)
        (apps/'probe.desktop').write_text(f'[Desktop Entry]\nType=Application\nName=Void Launcher Probe\nExec={probe}\nCategories=Utility;\nTerminal=false\n')
        runtime = self.base/'runtime'; runtime.mkdir(mode=0o700)
        env = {**self.env, 'DISPLAY': ':189', 'XDG_RUNTIME_DIR': str(runtime), 'QT_QPA_PLATFORM':'xcb', 'QT_QUICK_BACKEND':'software'}
        captures = pathlib.Path('/tmp/void-window-check'); captures.mkdir(exist_ok=True)
        log = open(self.base/'windows.log', 'w')
        processes = []
        def command(*args): return subprocess.run(args, env=env, text=True, capture_output=True, check=True).stdout
        def click(x,y): command('xdotool','mousemove',str(x),str(y)); command('xdotool','click','1'); time.sleep(.4)
        def bars(): return re.findall(r'(0x[0-9a-f]+) "quickshell": .*?1280x28\+', command('xwininfo','-root','-tree'))
        try:
            processes.append(subprocess.Popen(['Xvfb',':189','-screen','0','1280x800x24','-nolisten','tcp'], env=env, stdout=log, stderr=log))
            for _ in range(100):
                if subprocess.run(['xprop','-root'],env=env,capture_output=True).returncode == 0: break
                time.sleep(.05)
            processes.append(subprocess.Popen([str(data/'dwm')],env=env,stdout=log,stderr=log))
            time.sleep(.5)
            processes.append(subprocess.Popen(['quickshell','--path',str(data/'quickshell/shell.qml')],env=env,stdout=log,stderr=log))
            time.sleep(2)
            initial = bars(); self.assertEqual(len(initial),1)
            command('xsetroot','-solid','#5E81AC'); command('xsetroot','-name','01.11.2026 11:59'); time.sleep(.5)
            click(1266,14)
            command('magick','import','-window','root',str(captures/'power.png'))
            self.assertEqual(bars(), initial)
            command('xdotool','key','Escape'); time.sleep(.3)
            # Updates are to the right of the centered date.
            click(734,14)
            command('magick','import','-window','root',str(captures/'updates.png'))
            self.assertIn('380x',command('xwininfo','-root','-tree'))
            self.assertEqual(bars(), initial)
            command('xdotool','key','Escape'); time.sleep(.3)
            processes.append(subprocess.Popen(['quickshell','--path',str(data/'quickshell/launcher.qml')],env=env,stdout=log,stderr=log))
            time.sleep(2)
            window = command('xdotool','search','--onlyvisible','--name','^Void Applications$').split()[0]
            print(command('xprop','-id',window,'WM_CLASS','WM_NAME'))
            print(command('xwininfo','-id',window))
            geometry = dict(line.split('=',1) for line in command('xdotool','getwindowgeometry','--shell',window).splitlines() if '=' in line)
            self.assertEqual(int(geometry['WIDTH']),820)
            self.assertEqual(int(geometry['HEIGHT']),600)
            self.assertNotIn('_NET_WM_STATE_FULLSCREEN',command('xprop','-id',window,'_NET_WM_STATE'))
            self.assertEqual(bars(), initial, 'Launcher must not replace the bar')
            command('magick','import','-window','root',str(captures/'launcher.png'))
            command('xdotool','windowfocus',window); command('xdotool','type','Void Launcher Probe'); time.sleep(.4)
            command('xdotool','key','Return'); time.sleep(.5)
            self.assertEqual((self.home/'launched').read_text(), 'launched')
            self.assertEqual(bars(), initial)
            self.assertFalse((self.home/'actions').exists())
            log.flush(); self.assertNotIn('TypeError',(self.base/'windows.log').read_text())
            print('Installed private dwm: launcher 820x600, no fullscreen, bar unchanged; bounded power/update popups, no compositor, no system action.')
        finally:
            for process in reversed(processes):
                if process.poll() is None: process.terminate(); process.wait(timeout=5)
            log.close()

if __name__ == '__main__':
    unittest.main(defaultTest='WindowIntegrationTests.test_launcher_stays_windowed_and_panels_survive')