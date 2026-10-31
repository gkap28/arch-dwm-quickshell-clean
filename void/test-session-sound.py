"""Verify the Void session starts PipeWire only when missing and stops only its own sound children."""
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import time
import unittest

SESSION = pathlib.Path(__file__).with_name('session.sh')

STUB = '''#!{py}
import os, pathlib, signal, socket, sys, time
home = pathlib.Path(os.environ["HOME"])
name = pathlib.Path(sys.argv[0]).name
(home / (name + "-pid")).write_text(str(os.getpid()))
run = pathlib.Path(os.environ["XDG_RUNTIME_DIR"])
sock = {sock!r}
if sock:
    (run / sock).parent.mkdir(parents=True, exist_ok=True)
    s = socket.socket(socket.AF_UNIX); s.bind(str(run / sock))
def stop(*_):
    (home / (name + "-stopped")).write_text("stopped")
    sys.exit(0)
signal.signal(signal.SIGTERM, stop)
while True:
    time.sleep(.05)
'''

class SoundSessionTests(unittest.TestCase):
    def make(self, tmp, pgrep_running=()):
        home = pathlib.Path(tmp)
        data = home / '.local/share/dwm-void'
        data.mkdir(parents=True)
        run = home / 'run'
        run.mkdir(mode=0o700)
        binpath = home / 'bin'
        binpath.mkdir()
        for name in ['sh', 'sleep', 'kill', 'id']:
            program = shutil.which(name)
            if program:
                (binpath / name).symlink_to(program)
        (data / 'dwm').write_text('#!/bin/sh\nwhile [ ! -f "$HOME/finish" ]; do sleep .05; done\n')
        (data / 'dwm').chmod(0o755)
        for name, sock in [('pipewire', 'pipewire-0'), ('wireplumber', ''), ('pipewire-pulse', 'pulse/native')]:
            (binpath / name).write_text(STUB.format(py=sys.executable, sock=sock))
            (binpath / name).chmod(0o755)
        if pgrep_running is not None:
            names = ' '.join(pgrep_running)
            (binpath / 'pgrep').write_text('#!/bin/sh\nfor n in %s; do [ "$4" = "$n" ] && exit 0; done\nexit 1\n' % names)
            (binpath / 'pgrep').chmod(0o755)
        env = {**os.environ, 'HOME': str(home), 'PATH': str(binpath), 'XDG_RUNTIME_DIR': str(run)}
        return home, data, env

    def wait_for(self, path, seconds=6):
        for _ in range(int(seconds / .05)):
            if path.exists():
                return True
            time.sleep(.05)
        return False

    def test_starts_missing_pipewire_wireplumber_and_pulse_then_stops_them(self):
        with tempfile.TemporaryDirectory() as tmp:
            home, data, env = self.make(tmp)
            other = subprocess.Popen(['sleep', '30'])
            session = subprocess.Popen(['/bin/sh', str(SESSION)], env=env)
            try:
                for name in ['pipewire', 'wireplumber', 'pipewire-pulse']:
                    self.assertTrue(self.wait_for(home / (name + '-pid')), name)
                self.assertTrue((data / 'pipewire.log').exists())
                self.assertFalse((home / '.config').exists())
                (home / 'finish').touch()
                self.assertEqual(session.wait(timeout=10), 0)
                for name in ['pipewire', 'wireplumber', 'pipewire-pulse']:
                    self.assertTrue(self.wait_for(home / (name + '-stopped')), name)
                self.assertIsNone(other.poll())
            finally:
                if session.poll() is None:
                    session.terminate(); session.wait(timeout=5)
                other.terminate(); other.wait(timeout=5)

    def test_existing_pipewire_is_left_alone(self):
        with tempfile.TemporaryDirectory() as tmp:
            home, data, env = self.make(tmp, pgrep_running=['pipewire'])
            (home / 'finish').touch()
            self.assertEqual(subprocess.run(['/bin/sh', str(SESSION)], env=env, timeout=10).returncode, 0)
            for name in ['pipewire', 'wireplumber', 'pipewire-pulse']:
                self.assertFalse((home / (name + '-pid')).exists(), name)

    def test_wireplumber_launched_by_pipewire_is_not_doubled(self):
        with tempfile.TemporaryDirectory() as tmp:
            home, data, env = self.make(tmp, pgrep_running=['wireplumber'])
            session = subprocess.Popen(['/bin/sh', str(SESSION)], env=env)
            try:
                self.assertTrue(self.wait_for(home / 'pipewire-pid'))
                self.assertTrue(self.wait_for(home / 'pipewire-pulse-pid'))
                self.assertFalse((home / 'wireplumber-pid').exists())
            finally:
                (home / 'finish').touch()
                session.wait(timeout=10)

    def test_missing_runtime_dir_does_not_block_desktop(self):
        with tempfile.TemporaryDirectory() as tmp:
            home, data, env = self.make(tmp)
            env.pop('XDG_RUNTIME_DIR')
            (home / 'finish').touch()
            self.assertEqual(subprocess.run(['/bin/sh', str(SESSION)], env=env, timeout=10).returncode, 0)
            self.assertFalse((home / 'pipewire-pid').exists())
            self.assertIn('XDG_RUNTIME_DIR', (data / 'pipewire.log').read_text())

if __name__ == '__main__':
    unittest.main()
