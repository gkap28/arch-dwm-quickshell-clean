"""Actual Quickshell/X11 module clicks; audio/network settings tools are stubs."""
import os, pathlib, tempfile, subprocess, time, re, unittest

class PanelModuleTests(unittest.TestCase):
    def test_clicks_dispatch_settings(self):
        with tempfile.TemporaryDirectory() as tmp:
            home=pathlib.Path(tmp)
            data=home/'.local/share/dwm-void'
            data.mkdir(parents=True)
            source=pathlib.Path(__file__).parent
            (data/'modules.sh').write_text((source/'modules.sh').read_text())
            qml=home/'shell.qml'
            (home/'StatusModules.qml').write_text((source/'StatusModules.qml').read_text())
            qml.write_text('import QtQuick\nimport Quickshell\nShellRoot { PanelWindow { id: panel; anchors { top: true; left: true; right: true } implicitHeight: 28; color: "#2E3440"; StatusModules { anchors.right: parent.right; panel: panel; home: Quickshell.env("HOME") + "/.local/share/dwm-void/"; background: "#2E3440"; foreground: "#D8DEE9"; surface: "#434C5E"; accent: "#81A1C1" } } }')
            tools=home/'bin';tools.mkdir()
            for name in ['pavucontrol','nm-connection-editor']:
                p=tools/name;p.write_text(f'#!/bin/sh\necho opened > "$HOME/{name}-opened"\n');p.chmod(0o755)
            runtime=home/'runtime';runtime.mkdir(mode=0o700)
            env={**os.environ,'HOME':str(home),'DISPLAY':':199','XDG_RUNTIME_DIR':str(runtime),'QT_QPA_PLATFORM':'xcb','QT_QUICK_BACKEND':'software','PATH':str(tools)+':'+os.environ['PATH']}
            log=open(home/'log','w')
            server=subprocess.Popen(['Xvfb',':199','-screen','0','1280x800x24'],env=env,stdout=log,stderr=log)
            panel=None
            def command(*args):return subprocess.run(args,env=env,capture_output=True,text=True,check=True).stdout
            try:
                for _ in range(100):
                    if subprocess.run(['xprop','-root'],env=env,capture_output=True).returncode==0:break
                    time.sleep(.05)
                panel=subprocess.Popen(['quickshell','--path',str(qml)],env=env,stdout=log,stderr=log)
                time.sleep(1.5)
                for x,height,button_y,tool in [(1240,184,132,'pavucontrol'),(1165,144,95,'nm-connection-editor')]:
                    command('xdotool','mousemove',str(x),'14');command('xdotool','click','1');time.sleep(.4)
                    popups=re.findall(r'(0x[0-9a-f]+) "quickshell": .*?280x'+str(height)+r'\+',command('xwininfo','-root','-tree'))
                    self.assertTrue(popups,(home/'log').read_text())
                    command('xdotool','mousemove','--window',popups[0],'130' if height==184 else '60',str(button_y));command('xdotool','click','1');time.sleep(.5)
                    self.assertEqual((home/(tool+'-opened')).read_text().strip(),'opened')
                self.assertIsNone(panel.poll())
            finally:
                for process in [panel,server]:
                    if process and process.poll() is None:process.terminate();process.wait(timeout=5)
                log.close()
if __name__=='__main__':unittest.main()
