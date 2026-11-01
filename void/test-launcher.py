"""Real DesktopEntries search and launch; harmless application recorder only."""
import os, pathlib, subprocess, tempfile, time, unittest

class LauncherTests(unittest.TestCase):
    def test_search_and_launch(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = pathlib.Path(tmp)
            (home/'launcher.qml').write_bytes(pathlib.Path(__file__).with_name('launcher.qml').read_bytes())
            apps = home/'.local/share/applications'; apps.mkdir(parents=True)
            tool = home/'probe'; tool.write_text('#!/bin/sh\nprintf launched > "$HOME/launched"\n'); tool.chmod(0o755)
            (apps/'probe.desktop').write_text(f'[Desktop Entry]\nType=Application\nName=Void Launcher Probe\nGenericName=Test application\nExec={tool}\nCategories=Utility;\nTerminal=false\n')
            runtime = home/'runtime'; runtime.mkdir(mode=0o700)
            env = {**os.environ, 'HOME':tmp, 'XDG_DATA_HOME':str(home/'.local/share'), 'DISPLAY':':191', 'XDG_RUNTIME_DIR':str(runtime), 'QT_QPA_PLATFORM':'xcb', 'QT_QUICK_BACKEND':'software'}
            log = open(home/'log','w')
            server = subprocess.Popen(['Xvfb',':191','-screen','0','1280x800x24','-nolisten','tcp'],env=env,stdout=log,stderr=log)
            panel = None
            def command(*args): return subprocess.run(args,env=env,text=True,capture_output=True,check=True).stdout
            try:
                for _ in range(100):
                    if subprocess.run(['xprop','-root'],env=env,capture_output=True).returncode == 0: break
                    time.sleep(.05)
                panel = subprocess.Popen(['quickshell','--path',str(home/'launcher.qml')],env=env,stdout=log,stderr=log)
                time.sleep(2)
                self.assertIsNone(panel.poll(),(home/'log').read_text())
                window = command('xdotool','search','--onlyvisible','--name','^Void Applications$').split()[0]
                command('xdotool','windowfocus',window)
                command('xdotool','type','Void Launcher Probe'); time.sleep(.5)
                capture = pathlib.Path('/tmp/void-launcher-check'); capture.mkdir(exist_ok=True)
                command('magick','import','-window',window,str(capture/'search.png'))
                command('xdotool','key','Return')
                for _ in range(30):
                    if (home/'launched').exists(): break
                    time.sleep(.1)
                self.assertEqual((home/'launched').read_text(),'launched')
                self.assertNotIn('TypeError',(home/'log').read_text())
            finally:
                for p in [panel,server]:
                    if p and p.poll() is None: p.terminate(); p.wait(timeout=5)
                log.close()

if __name__ == '__main__': unittest.main()