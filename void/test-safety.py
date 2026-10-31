"""Installer safety regression tests; run with Python 3 and build dependencies.
Uses an isolated copy for OS/UID gates; never edits the host's os-release.
"""
import os, pathlib, shutil, subprocess, tempfile, unittest
ROOT = pathlib.Path(__file__).resolve().parents[1]
class SafetyTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='void-safety-')
        self.base = pathlib.Path(self.tmp.name)
        self.repo = self.base/'repo'; self.repo.mkdir()
        for name in ['dwm.c','drw.c','drw.h','util.c','util.h','tomlparser.c','tomlparser.h','config.def.h','config.mk']:
            shutil.copy(ROOT/name,self.repo/name)
        shutil.copytree(ROOT/'void',self.repo/'void')
        p=self.repo/'void/start.sh'
        s=p.read_text().replace('[ "$(id -u)" -ne 0 ]','[ 1000 -ne 0 ]').replace('[ -r /etc/os-release ]','[ -r "$VOID_TEST_OS" ]').replace('. /etc/os-release','. "$VOID_TEST_OS"')
        p.write_text(s)
        self.home=self.base/'home'; self.home.mkdir()
        self.bin=self.base/'bin'; self.bin.mkdir()
        for name in ['startx','alacritty','xsetroot']:
            f=self.bin/name;f.write_text('#!/bin/sh\nexit 0\n');f.chmod(0o755)
        # Hermetic stubs: safety tests must not depend on host libraries.
        f=self.bin/'pkg-config';f.write_text('#!/bin/sh\nexit 0\n');f.chmod(0o755)
        f=self.bin/'make';f.write_text('#!/bin/sh\nwhile [ $# -gt 0 ]; do [ "$1" = -C ] && dir=$2; shift; done; : > "$dir/dwm"\n');f.chmod(0o755)
        self.osfile=self.base/'os-release';self.osfile.write_text('ID=void\n')
        self.env={**os.environ,'HOME':str(self.home),'VOID_TEST_OS':str(self.osfile),'PATH':str(self.bin)+':'+os.environ['PATH']}
    def tearDown(self):self.tmp.cleanup()
    def run_install(self):return subprocess.run(['sh',str(self.repo/'void/start.sh'),'--install'],env=self.env,capture_output=True,text=True)
    def test_arch_refused_without_writes(self):
        self.osfile.write_text('ID=arch\n')
        self.assertNotEqual(self.run_install().returncode,0)
        self.assertEqual(list(self.home.iterdir()),[])
    def test_symlink_refused_without_writes(self):
        (self.home/'.local/share').mkdir(parents=True)
        outside=self.base/'outside';outside.mkdir()
        (self.home/'.local/share/dwm-void').symlink_to(outside,target_is_directory=True)
        self.assertNotEqual(self.run_install().returncode,0)
        self.assertEqual(list(outside.iterdir()),[])
    def test_existing_files_preserved(self):
        data=self.home/'.local/share/dwm-void';(data/'config').mkdir(parents=True)
        (data/'config/hotkeys.toml').write_text('# keep\n')
        (self.home/'.config/quickshell').mkdir(parents=True)
        (self.home/'.config/quickshell/shell.qml').write_text('keep')
        (self.home/'.xinitrc').write_text('keep')
        before={p.name:p.read_bytes() for p in self.repo.iterdir() if p.is_file()}
        result=self.run_install();self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual((data/'config/hotkeys.toml').read_text(),'# keep\n')
        self.assertEqual((self.home/'.xinitrc').read_text(),'keep')
        self.assertEqual((self.home/'.config/quickshell/shell.qml').read_text(),'keep')
        self.assertEqual(before,{p.name:p.read_bytes() for p in self.repo.iterdir() if p.is_file()})
        self.assertEqual(sorted(p.name for p in data.iterdir()),['config','dwm','monitors.sh','status.sh','xinitrc'])
        self.assertIn('status.sh" &',(data/'xinitrc').read_text())
        session=(data/'xinitrc').read_text()
        self.assertLess(session.index('/monitors.sh'),session.index('/dwm"'))
if __name__=='__main__':unittest.main()