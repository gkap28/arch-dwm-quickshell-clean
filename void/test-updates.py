"""Update checks/actions with fake package managers; no real updates."""
import os, pathlib, subprocess, tempfile, unittest
SCRIPT=pathlib.Path(__file__).with_name('updates.sh')
class UpdateTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.home=pathlib.Path(self.tmp.name); self.bin=self.home/'bin'; self.bin.mkdir()
        self.env={**os.environ,'HOME':str(self.home),'PATH':str(self.bin)+':/usr/bin:/bin'}
        self.tool('xbps-install','printf "%s\\n" "$*" >> "$HOME/xbps-calls"\nprintf "one-1_1 update\\ntwo-2_1 update\\n"')
        self.tool('flatpak','printf "%s\\n" "$*" >> "$HOME/flatpak-calls"\ncase "$*" in *--user*) printf "app/test/stable\\n";; *--system*) printf "runtime/test/stable\\napp/other/stable\\n";; esac')
    def tool(self,name,body):
        p=self.bin/name;p.write_text('#!/bin/sh\n'+body+'\n');p.chmod(0o755)
    def run_helper(self,action): return subprocess.run(['sh',str(SCRIPT),action],env=self.env,capture_output=True,text=True)
    def test_read_only_counts_both_installations(self):
        result=self.run_helper('status'); self.assertEqual(result.stdout,'2\t3\n')
        self.assertEqual((self.home/'xbps-calls').read_text(),'-Mun\n')
        self.assertEqual((self.home/'flatpak-calls').read_text(),'remote-ls --updates --user --columns=ref\nremote-ls --updates --system --columns=ref\n')
    def test_flatpak_button_opens_own_interactive_command(self):
        self.tool('alacritty','printf "%s\\n" "$@" > "$HOME/terminal"')
        self.assertEqual(self.run_helper('flatpak').returncode,0)
        args=(self.home/'terminal').read_text()
        self.assertIn('flatpak update --user;',args); self.assertIn('flatpak update --system;',args)
        self.assertNotIn('xbps-install',args); self.assertFalse((self.home/'flatpak-calls').exists())
    def test_failed_query_is_unavailable_not_zero(self):
        self.tool('xbps-install','exit 1')
        self.assertEqual(self.run_helper('status').stdout,'-1\t3\n')
    def test_unknown_action_does_nothing(self):
        self.assertNotEqual(self.run_helper('anything').returncode,0)
        self.assertFalse((self.home/'xbps-calls').exists()); self.assertFalse((self.home/'flatpak-calls').exists())
if __name__=='__main__': unittest.main()