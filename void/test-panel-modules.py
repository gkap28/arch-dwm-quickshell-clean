"""Actual Quickshell/X11 module clicks; audio/network settings tools are stubs."""
import os, pathlib, tempfile, subprocess, time, re, unittest
import importlib.util
spec = importlib.util.spec_from_file_location("module_details_fixture", pathlib.Path(__file__).with_name("test-module-details.py"))
fixture_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixture_module)
DetailTests = fixture_module.DetailTests

class PanelModuleTests(unittest.TestCase):
    def test_clicks_dispatch_settings(self):
        with tempfile.TemporaryDirectory() as tmp:
            home=pathlib.Path(tmp)
            data=home/'.local/share/dwm-void'
            data.mkdir(parents=True)
            source=pathlib.Path(__file__).parent
            (data/'modules.sh').write_text((source/'modules.sh').read_text())
            (data/'module-details.sh').write_text((source/'module-details.sh').read_text())
            qml=home/'shell.qml'
            (home/'StatusModules.qml').write_text((source/'StatusModules.qml').read_text())
            qml.write_text('import QtQuick\nimport Quickshell\nShellRoot { PanelWindow { id: panel; anchors { top: true; left: true; right: true } implicitHeight: 28; color: "#2E3440"; StatusModules { anchors.right: parent.right; panel: panel; home: Quickshell.env("HOME") + "/.local/share/dwm-void/"; background: "#2E3440"; foreground: "#D8DEE9"; surface: "#434C5E"; accent: "#81A1C1" } } }')
            tools=home/'bin';tools.mkdir()
            fixture=DetailTests();fixture.setUp()
            self.addCleanup(fixture.tearDown)
            for name in ['pactl','nmcli','playerctl']:
                (tools/name).write_bytes((fixture.base/name).read_bytes()); (tools/name).chmod(0o755)
            for name in ['pavucontrol','nm-connection-editor']:
                p=tools/name;p.write_text(f'#!/bin/sh\necho opened > "$HOME/{name}-opened"\n');p.chmod(0o755)
            runtime=home/'runtime';runtime.mkdir(mode=0o700)
            env={**os.environ,'HOME':str(home),'DISPLAY':':199','XDG_RUNTIME_DIR':str(runtime),'QT_QPA_PLATFORM':'xcb','QT_QUICK_BACKEND':'software','PATH':str(tools)+':'+os.environ['PATH'],'RECORD':str(home/'record')}
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
                command('xdotool','mousemove','1240','14');command('xdotool','click','1');time.sleep(.6)
                tree=command('xwininfo','-root','-tree')
                popups=re.findall(r'(0x[0-9a-f]+) "quickshell": .*?1280x772\+',tree)
                self.assertTrue(popups,(home/'log').read_text())
                pathlib.Path('/tmp/void-popup-check').mkdir(exist_ok=True)
                command('magick','import','-window','root','/tmp/void-popup-check/audio.png')
                command('xdotool','mousemove','1080','320');command('xdotool','click','1');time.sleep(.6)
                self.assertEqual((home/'record').read_text().strip(),'set-default-sink hdmi')
                self.assertEqual((home/'record.default').read_text().strip(),'hdmi')
                command('magick','import','-window','root','/tmp/void-popup-check/audio-selected.png')
                # Dismiss the actual audio popup by clicking outside its framed surface.
                command('xdotool','mousemove','100','100');command('xdotool','click','1');time.sleep(.2)
                command('xdotool','mousemove','1165','14');command('xdotool','click','1');time.sleep(.4)
                command('magick','import','-window','root','/tmp/void-popup-check/network.png')
                command('xdotool','mousemove','1200','390');command('xdotool','click','1');time.sleep(.5)
                self.assertEqual((home/'record').read_text().strip(),'connection up uuid 123-456')
                command('xdotool','mousemove','970','670');command('xdotool','click','1');time.sleep(.5)
                self.assertEqual((home/'nm-connection-editor-opened').read_text().strip(),'opened')
                command('xdotool','key','Escape');time.sleep(.2)
                self.assertNotIn('1280x772+',command('xwininfo','-root','-tree'))
                self.assertIsNone(panel.poll())
            finally:
                for process in [panel,server]:
                    if process and process.poll() is None:process.terminate();process.wait(timeout=5)
                log.close()
if __name__=='__main__':unittest.main()