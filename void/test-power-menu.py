"""Real QML clicks with recorded actions only; never changes a real session."""
import os, pathlib, re, subprocess, tempfile, time, unittest

class PowerMenuTests(unittest.TestCase):
    def test_five_actions_and_confirmation(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = pathlib.Path(tmp)
            source = pathlib.Path(__file__).parent
            (home/'PowerMenu.qml').write_bytes((source/'PowerMenu.qml').read_bytes())
            (home/'shell.qml').write_text('''import QtQuick
import Quickshell
ShellRoot { PanelWindow { id: panel; anchors { top: true; left: true; right: true }
implicitHeight: 28; color: "#2E3440"
PowerMenu { anchors.right: parent.right; panel: panel; home: Quickshell.env("HOME") + "/";
background: "#2E3440"; foreground: "#D8DEE9"; surface: "#434C5E"; accent: "#81A1C1" }
} }''')
            (home/'power-action.sh').write_text('#!/bin/sh\nprintf "%s\\n" "$1" >> "$HOME/actions"\n')
            tools = home/'bin'; tools.mkdir()
            (tools/'loginctl').write_text('#!/bin/sh\necho yes\n'); (tools/'loginctl').chmod(0o755)
            runtime = home/'runtime'; runtime.mkdir(mode=0o700)
            env = {**os.environ, 'HOME':tmp, 'DISPLAY':':193', 'XDG_RUNTIME_DIR':str(runtime),
                   'QT_QPA_PLATFORM':'xcb', 'QT_QUICK_BACKEND':'software', 'PATH':str(tools)+':'+os.environ['PATH']}
            log = open(home/'log','w')
            server = subprocess.Popen(['Xvfb',':193','-screen','0','1280x800x24','-nolisten','tcp'], env=env, stdout=log, stderr=log)
            panel = None
            def command(*args):
                return subprocess.run(args, env=env, text=True, capture_output=True, check=True).stdout
            def click(x,y):
                command('xdotool','mousemove',str(x),str(y)); command('xdotool','click','1'); time.sleep(.25)
            def recorded():
                return (home/'actions').read_text().splitlines() if (home/'actions').exists() else []
            try:
                for _ in range(100):
                    if subprocess.run(['xprop','-root'],env=env,capture_output=True).returncode == 0: break
                    time.sleep(.05)
                panel = subprocess.Popen(['quickshell','--path',str(home/'shell.qml')],env=env,stdout=log,stderr=log)
                time.sleep(2)
                self.assertIsNone(panel.poll(),(home/'log').read_text())
                click(1266,14)
                capture=pathlib.Path('/tmp/void-power-check'); capture.mkdir(exist_ok=True)
                command('magick','import','-window','root',str(capture/'menu.png'))
                self.assertIn('1280x772+',command('xwininfo','-root','-tree')+(home/'log').read_text())
                command('xdotool','key','Escape'); time.sleep(.2)
                self.assertEqual(recorded(),[])
                self.assertNotIn('1280x772+',command('xwininfo','-root','-tree'))
                expected=[]
                # Positions are inside the five actual visible QML action rows.
                for index,action in enumerate(['reboot','logout','lock','suspend','shutdown']):
                    click(1266,14); click(1080,91+38*index)
                    if action != 'lock':
                        self.assertEqual(recorded(),expected,'Selection must not execute '+action)
                        command('magick','import','-window','root',str(capture/(action+'-confirmation.png')))
                        # Escape returns to the list without executing anything.
                        command('xdotool','key','Escape'); time.sleep(.2)
                        self.assertEqual(recorded(),expected)
                        click(1080,91+38*index)
                        click(1200,176 if action == 'suspend' else 152)
                    expected.append(action)
                    self.assertEqual(recorded(),expected)
                    click(100,100)
                self.assertIsNone(panel.poll(),(home/'log').read_text())
                self.assertNotIn('TypeError',(home/'log').read_text())
                print('Five real QML actions recorded; four require confirmation; Escape/outside click safe. No real power action executed.')
            finally:
                for process in [panel,server]:
                    if process and process.poll() is None: process.terminate(); process.wait(timeout=5)
                log.close()

if __name__ == '__main__': unittest.main()