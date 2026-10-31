"""Verify optional Picom autostart and cleanup with isolated process stubs."""
import os
import pathlib
import shutil
import subprocess
import tempfile
import time
import unittest

class SessionTests(unittest.TestCase):
    def test_installed_picom_starts_and_only_own_child_stops(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = pathlib.Path(tmp)
            data = home / '.local/share/dwm-void'
            data.mkdir(parents=True)
            binpath = home / 'bin'
            binpath.mkdir()
            for name in ['sh', 'sleep', 'kill']:
                program = shutil.which(name)
                if program:
                    (binpath / name).symlink_to(program)
            (data / 'dwm').write_text('#!/bin/sh\nwhile [ ! -f "$HOME/finish" ]; do sleep .05; done\n')
            (data / 'dwm').chmod(0o755)
            (binpath / 'picom').write_text('#!/bin/sh\necho $$ > "$HOME/picom-pid"\ntrap \'echo stopped > "$HOME/picom-stopped"; exit\' TERM\nwhile :; do sleep .05; done\n')
            (binpath / 'picom').chmod(0o755)
            env = {**os.environ, 'HOME': str(home), 'PATH': str(binpath)}
            other = subprocess.Popen(['sleep', '30'])
            session = subprocess.Popen(['/bin/sh', str(pathlib.Path(__file__).with_name('session.sh'))], env=env)
            try:
                for _ in range(100):
                    if (home / 'picom-pid').exists():
                        break
                    time.sleep(.05)
                self.assertTrue((home / 'picom-pid').exists())
                self.assertTrue((data / 'picom.log').exists())
                self.assertFalse((home / '.config').exists())
                (home / 'finish').touch()
                self.assertEqual(session.wait(timeout=5), 0)
                for _ in range(100):
                    if (home / 'picom-stopped').exists():
                        break
                    time.sleep(.05)
                self.assertEqual((home / 'picom-stopped').read_text().strip(), 'stopped')
                self.assertIsNone(other.poll())
                (binpath / 'picom').unlink()
                (home / 'picom-pid').unlink()
                self.assertEqual(subprocess.run(['/bin/sh', str(pathlib.Path(__file__).with_name('session.sh'))], env=env, timeout=5).returncode, 0)
                self.assertFalse((home / 'picom-pid').exists())
            finally:
                if session.poll() is None:
                    session.terminate()
                    session.wait(timeout=5)
                other.terminate()
                other.wait(timeout=5)

if __name__ == '__main__':
    unittest.main()
