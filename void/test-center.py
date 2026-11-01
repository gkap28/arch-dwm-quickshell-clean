"""Concrete preference rules and isolated read-only system facts."""
import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).parent

class CenterTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.home = pathlib.Path(self.temp.name)
        self.env = {**os.environ, 'HOME': str(self.home)}

    def tearDown(self): self.temp.cleanup()

    def run_settings(self, *args):
        return subprocess.run(['sh', str(ROOT/'center-settings.sh'), *args], env=self.env, capture_output=True, text=True)

    def test_defaults_existing_modules_on_seconds_off(self):
        result = self.run_settings('read')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, 'power=1\nvolume=1\nnetwork=1\nlayout=1\nseconds=0\ntimeout=0\n')

    def test_power_toggle_roundtrip(self): self.toggle('power')
    def test_volume_toggle_roundtrip(self): self.toggle('volume')
    def test_network_toggle_roundtrip(self): self.toggle('network')
    def test_layout_toggle_roundtrip(self): self.toggle('layout')
    def test_seconds_toggle_roundtrip(self): self.toggle('seconds')

    def toggle(self, key):
        for value in (0, 1):
            result = self.run_settings('set', key, str(value))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(f'{key}={value}\n', self.run_settings('read').stdout)
        self.assertFalse((self.home/'.config').exists())

    def test_invalid_values_cannot_overwrite_settings(self):
        self.run_settings('set', 'seconds', '1')
        file = self.home/'.local/share/dwm-void/config/center.conf'
        before = file.read_bytes()
        for args in [('seconds', '2'), ('timeout', '60'), ('unknown', '1'), ('power', '$(touch nope)')]:
            self.assertNotEqual(self.run_settings('set', *args).returncode, 0)
        self.assertEqual(file.read_bytes(), before)

    def test_symlink_settings_refused(self):
        directory = self.home/'.local/share/dwm-void/config'; directory.mkdir(parents=True)
        outside = self.home/'outside'; outside.write_text('keep')
        (directory/'center.conf').symlink_to(outside)
        self.assertNotEqual(self.run_settings('set', 'power', '0').returncode, 0)
        self.assertEqual(outside.read_text(), 'keep')

    def test_seconds_format_keeps_requested_spacing(self):
        result = subprocess.run(['sh', '-c', '. "$1"; clock_text 0 01 11 13.40.07', 'sh', str(ROOT/'clock-format.sh')], capture_output=True, text=True)
        self.assertEqual(result.stdout, 'So 01 Nov - 13.40.07\n')

    def test_unknown_action_refused(self):
        result = subprocess.run(['sh', str(ROOT/'center-action.sh'), 'delete-all'], env=self.env, capture_output=True)
        self.assertEqual(result.returncode, 2)

    def test_system_facts_read_real_kernel(self):
        result = subprocess.run(['sh', str(ROOT/'system-info.sh')], env=self.env, capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0)
        self.assertIn(f'Kernel\t{os.uname().sysname} {os.uname().release}\n', result.stdout)
        self.assertFalse((self.home/'.config').exists())

if __name__ == '__main__': unittest.main()