"""Concrete requested shortcuts and preservation during an existing-install update."""
import os, pathlib, subprocess, tempfile, tomllib, unittest
ROOT=pathlib.Path(__file__).resolve().parent
class HotkeyTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(); self.home=pathlib.Path(self.tmp.name)
        self.file=self.home/'.local/share/dwm-void/config/hotkeys.toml'; self.file.parent.mkdir(parents=True)
        self.original=(ROOT/'hotkeys.toml').read_text(); self.file.write_text(self.original)
        self.script=self.home/'update.sh'
        self.script.write_text((ROOT/'update-hotkeys.sh').read_text().replace('[ "$(id -u)" -ne 0 ]','[ 1000 -ne 0 ]'))
        self.env={**os.environ,'HOME':str(self.home)}
        subprocess.run(['sh',str(self.script)],env=self.env,check=True,capture_output=True)
        self.keys=tomllib.loads(self.file.read_text())['vars']['keys']
    def tearDown(self): self.tmp.cleanup()
    def key(self,mod,key):
        matches=[x for x in self.keys if x['mod']==mod and x['key']==key]
        self.assertEqual(len(matches),1); return matches[0]
    def test_super_q_closes_window(self): self.assertEqual(self.key('SUPER','q')['func'],'killclient')
    def test_shift_return_thunar(self): self.assertEqual(self.key('SUPER SHIFT','Return')['exec'],['thunar'])
    def test_return_alacritty(self): self.assertEqual(self.key('SUPER','Return')['exec'],['alacritty'])
    def test_b_brave(self):
        command=self.key('SUPER','b')['cmd']
        bin=self.home/'bin'; bin.mkdir()
        brave=bin/'brave'; brave.write_text('#!/bin/sh\nprintf brave\n'); brave.chmod(0o755)
        result=subprocess.run(['sh','-c',command],env={**self.env,'PATH':str(bin)+':'+self.env['PATH']},capture_output=True,text=True)
        self.assertEqual(result.stdout,'brave'); self.assertEqual(result.returncode,0)
    def test_preserves_other_keys_and_backup(self):
        self.assertEqual(self.key('SUPER','x')['exec'],['$terminal'])
        self.assertEqual(self.key('SUPER SHIFT','q')['func'],'quit')
        self.assertEqual(self.file.with_name('hotkeys.toml.before-app-keys').read_text(),self.original)
        before=self.file.read_text()
        subprocess.run(['sh',str(self.script)],env=self.env,check=True,capture_output=True)
        self.assertEqual(self.file.read_text(),before)
if __name__=='__main__': unittest.main()