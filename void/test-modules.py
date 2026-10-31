"""Hermetic audio/network state and action checks; no host settings changed."""
import pathlib, tempfile, os, subprocess, unittest
MODULES = pathlib.Path(__file__).with_name('modules.sh')
class ModuleTests(unittest.TestCase):
    def test_audio_and_network_states_and_actions(self):
        with tempfile.TemporaryDirectory() as tmp:
            base=pathlib.Path(tmp)
            (base/'pactl').write_text('#!/bin/sh\ncase "$1" in get-sink-volume) echo "Volume: front-left: 32768 / 50% / -18 dB" ;; get-sink-mute) echo "Mute: yes" ;; *) printf "%s\\n" "$*" > "$RECORD" ;; esac\n')
            (base/'nmcli').write_text('#!/bin/sh\necho "ethernet:connected"\n')
            for p in base.iterdir(): p.chmod(0o755)
            env={**os.environ,'PATH':str(base)+':'+os.environ['PATH'],'RECORD':str(base/'record')}
            def run(*args): return subprocess.run(['sh',str(MODULES),*args],env=env,capture_output=True,text=True)
            self.assertEqual(run('status').stdout,'50\t1\tethernet\n')
            (base/'nmcli').write_text('#!/bin/sh\necho "wifi:disconnected"\n')
            self.assertEqual(run('status').stdout,'50\t1\toffline\n')
            (base/'nmcli').write_text('#!/bin/sh\necho "wifi:connected"\n')
            self.assertEqual(run('status').stdout,'50\t1\twifi\n')
            self.assertEqual(run('volume','67').returncode,0)
            self.assertEqual((base/'record').read_text().strip(),'set-sink-volume @DEFAULT_SINK@ 67%')
            self.assertNotEqual(run('volume','101').returncode,0)
            self.assertEqual(run('mute').returncode,0)
            self.assertEqual((base/'record').read_text().strip(),'set-sink-mute @DEFAULT_SINK@ toggle')
if __name__=='__main__': unittest.main()
