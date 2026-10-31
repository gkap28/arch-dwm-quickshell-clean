"""Assert Georg's exact screen arrangement and safe missing-screen behavior."""
import os, pathlib, subprocess, tempfile, unittest
ROOT=pathlib.Path(__file__).resolve().parent
class MonitorTests(unittest.TestCase):
    def run_layout(self, outputs):
        with tempfile.TemporaryDirectory() as tmp:
            base=pathlib.Path(tmp); cmd=base/'xrandr'; log=base/'args'
            cmd.write_text('#!/bin/sh\nif [ "$1" = --query ]; then printf "%s\\n" "$OUTPUTS"; else printf "%s\\n" "$@" > "$LOG"; fi\n'); cmd.chmod(0o755)
            env={**os.environ,'PATH':tmp+':'+os.environ['PATH'],'OUTPUTS':outputs,'LOG':str(log)}
            result=subprocess.run(['sh',str(ROOT/'monitors.sh')],env=env,capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr)
            return log.read_text().splitlines() if log.exists() else []
    def test_exact_left_and_right_layout(self):
        self.assertEqual(self.run_layout('HDMI-A-0 connected 2560x1080+0+0\nDisplayPort-2 connected 1920x1080+2560+0'),[
            '--output','HDMI-A-0','--mode','2560x1080','--pos','0x0','--rotate','normal',
            '--output','DisplayPort-2','--mode','1920x1080','--pos','2560x0','--rotate','normal'])
    def test_missing_right_screen_leaves_display_untouched(self):
        self.assertEqual(self.run_layout('HDMI-A-0 connected\nDisplayPort-2 disconnected'),[])
    def test_missing_left_screen_leaves_display_untouched(self):
        self.assertEqual(self.run_layout('HDMI-A-0 disconnected\nDisplayPort-2 connected'),[])
if __name__=='__main__':unittest.main()