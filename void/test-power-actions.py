import os, pathlib, subprocess, tempfile, unittest
SCRIPT = pathlib.Path(__file__).with_name('power-action.sh')
class PowerTests(unittest.TestCase):
    def test_login_actions_are_allowlisted(self):
        with tempfile.TemporaryDirectory() as tmp:
            path=pathlib.Path(tmp)
            for name in ['loginctl','pkill','slock','xmessage']:
                p=path/name
                p.write_text('#!/bin/sh\nprintf "%s " "'+name+'" "$@" >> "$HOME/actions"\n')
                p.chmod(0o755)
            env={**os.environ,'HOME':tmp,'PATH':tmp+':/usr/bin:/bin'}
            for action, expected in [('reboot','loginctl reboot'),('shutdown','loginctl poweroff'),('suspend','loginctl suspend'),('lock','slock')]:
                result=subprocess.run(['sh',str(SCRIPT),action],env=env)
                self.assertEqual(result.returncode,0)
                self.assertEqual((path/'actions').read_text().strip(),expected)
                (path/'actions').unlink()
            result=subprocess.run(['sh',str(SCRIPT),'anything-else'],env=env)
            self.assertNotEqual(result.returncode,0)
            self.assertTrue((path/'actions').read_text().startswith('xmessage '))
if __name__=='__main__':unittest.main()