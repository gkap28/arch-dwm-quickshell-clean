"""Quickshell 0.3.2 + isolated PipeWire null output: no actual hardware touched."""
import os, pathlib, subprocess, tempfile, time, unittest

class NativeAudioTests(unittest.TestCase):
    def test_native_volume_without_pactl(self):
        with tempfile.TemporaryDirectory() as tmp:
            home=pathlib.Path(tmp); runtime=home/'runtime'; runtime.mkdir(mode=0o700)
            env={**os.environ,'HOME':tmp,'XDG_RUNTIME_DIR':str(runtime),'DISPLAY':':197','QT_QPA_PLATFORM':'xcb','QT_QUICK_BACKEND':'software'}
            source=pathlib.Path(__file__).parent
            (home/'StatusModules.qml').write_bytes((source/'StatusModules.qml').read_bytes())
            (home/'modules.sh').write_text('#!/bin/sh\nprintf "%s\\t%s\\t%s\\n" -1 0 offline\n')
            (home/'module-details.sh').write_text('#!/bin/sh\nexit 0\n')
            cfg=home/'pipewire.conf'
            original=pathlib.Path(os.environ['PW_CONFIG']).read_text()
            cfg.write_text(original.replace('context.objects = [','''context.objects = [
{ factory = metadata args = { metadata.name = default } }
{ factory = adapter args = { factory.name = support.null-audio-sink node.name = test-speaker node.description = "Test speakers" media.class = Audio/Sink audio.position = "FL,FR" node.param.Props = { volume = 0.5 } } }
'''))
            qml=home/'shell.qml'
            qml.write_text('''import QtQuick
import Quickshell
import Quickshell.Io
ShellRoot { PanelWindow {
 id: panel; anchors { top: true; left: true; right: true }; implicitHeight: 28; color: "#2E3440"
 StatusModules { id: audio; anchors.right: parent.right; panel: panel; home: Quickshell.env("HOME") + "/"; background: "#2E3440"; foreground: "#D8DEE9"; surface: "#434C5E"; accent: "#81A1C1" }
 Timer { interval: 500; running: true; repeat: true; onTriggered: console.log("STATE", audio.nativeReady, audio.volume, audio.muted, audio.outputs.length) }
} }
'''.replace('right: true };','right: true }'))
            log=open(home/'log','w'); pwlog=open(home/'pwlog','w'); processes=[]
            def command(*args): return subprocess.run(args,env=env,capture_output=True,text=True,check=True).stdout
            try:
                processes.append(subprocess.Popen(['Xvfb',':197','-screen','0','1280x800x24'],env=env,stdout=log,stderr=log))
                processes.append(subprocess.Popen(['pipewire','-c',str(cfg)],env=env,stdout=pwlog,stderr=pwlog))
                for _ in range(60):
                    if (runtime/'pipewire-0').exists(): break
                    time.sleep(.1)
                nodes=command('pw-cli','ls','Node')
                import re
                match=re.search(r'id (\d+),.*?node.name = "test-speaker"',nodes,re.S)
                self.assertIsNotNone(match,nodes)
                # Metadata uses node.name, no policy manager or hardware required.
                metadata=subprocess.Popen(['pw-metadata','-n','default','0','default.audio.sink','{"name":"test-speaker"}','Spa:String:JSON'],env=env,stdout=pwlog,stderr=pwlog)
                processes.append(metadata)
                time.sleep(.4)
                processes.append(subprocess.Popen(['quickshell','--path',str(qml)],env=env,stdout=log,stderr=log))
                time.sleep(4)
                self.assertIn('STATE true 100 false 1', (home/'log').read_text())
                command('xdotool','mousemove','1240','14'); time.sleep(1)
                pathlib.Path('/tmp/void-native-check').mkdir(exist_ok=True)
                command('magick','import','-window','root','/tmp/void-native-check/hint.png')
                command('xdotool','click','1'); time.sleep(.4)
                command('magick','import','-window','root','/tmp/void-native-check/audio.png')
                # Mute through the actual popup; state must read back natively.
                command('xdotool','mousemove','1200','185'); command('xdotool','click','1'); time.sleep(.6)
                self.assertIn('STATE true 100 true 1', (home/'log').read_text())
                command('magick','import','-window','root','/tmp/void-native-check/muted.png')
            finally:
                for p in reversed(processes):
                    if p.poll() is None: p.terminate(); p.wait(timeout=5)
                log.close(); pwlog.close()
if __name__=='__main__': unittest.main()