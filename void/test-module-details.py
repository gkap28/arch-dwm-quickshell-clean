"""Hermetic user-session detail/actions tests; no host settings changed."""
import os, pathlib, subprocess, tempfile, unittest
HELPER = pathlib.Path(__file__).with_name('module-details.sh')

class DetailTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.base = pathlib.Path(self.tmp.name)
        self.env = {**os.environ, 'PATH': str(self.base) + ':' + os.environ['PATH'], 'RECORD': str(self.base/'record')}
        self.tool('pactl', '''case "$*" in
"list sinks") printf '    Name: speaker\n    Description: Main speakers\n    Name: hdmi\n    Description: HDMI Audio\n' ;;
"get-default-sink") if [ -f "$RECORD.default" ]; then cat "$RECORD.default"; else echo speaker; fi ;;
"get-sink-volume @DEFAULT_SINK@") echo 'Volume: 50%' ;;
"get-sink-mute @DEFAULT_SINK@") echo 'Mute: no' ;;
"get-source-mute @DEFAULT_SOURCE@") echo 'Mute: no' ;;
set-default-sink*) echo "$2" > "$RECORD.default"; printf '%s\n' "$*" > "$RECORD" ;;
*) printf '%s\n' "$*" > "$RECORD" ;;
esac''')
        self.tool('nmcli', '''case "$*" in
"general status") echo connected ;;
"-t -f TYPE,STATE device status") echo 'ethernet:connected' ;;
"-g UUID connection show") echo 123-456 ;;
"-g DEVICE device status") echo eth0 ;;
"--escape no -g BSSID device wifi list") echo AA:BB:CC:DD:EE:FF ;;
"-t -f NAME,UUID,TYPE,DEVICE connection show --active") echo 'Home:123-456:ethernet:eth0' ;;
"-t -f IN-USE,SSID,SIGNAL,SECURITY,BSSID device wifi list --rescan no") echo '*:Home:95:WPA2:AA\\:BB\\:CC\\:DD\\:EE\\:FF' ;;
"-t -f NAME,UUID,TYPE connection show") echo 'Home:123-456:ethernet' ;;
*) printf '%s\n' "$*" > "$RECORD"; if [ "$1" = --ask ]; then cat > "$RECORD.stdin"; fi ;;
esac''')
        self.tool('playerctl', 'case "$1" in -l) echo brave ;; metadata) echo "Artist — Song" ;; *) echo "$*" > "$RECORD" ;; esac')
    def tearDown(self): self.tmp.cleanup()
    def tool(self, name, body):
        p=self.base/name; p.write_text('#!/bin/sh\n'+body+'\n'); p.chmod(0o755)
    def run_action(self, *args, input=None):
        return subprocess.run(['sh', str(HELPER), *args], env=self.env, input=input, capture_output=True, text=True)
    def test_details_read_back(self):
        result=self.run_action('read'); self.assertEqual(result.returncode, 0)
        self.assertIn('output\thdmi\tHDMI Audio\n', result.stdout)
        self.assertIn('active\tHome:123-456:ethernet:eth0\n', result.stdout)
        self.assertIn('media\tbrave\tArtist — Song\n', result.stdout)
    def test_selected_output_only(self):
        self.assertEqual(self.run_action('output', 'hdmi').returncode, 0)
        self.assertEqual((self.base/'record').read_text().strip(), 'set-default-sink hdmi')
        self.assertNotEqual(self.run_action('output', 'unknown').returncode, 0)
    def test_selected_profile_only(self):
        self.assertEqual(self.run_action('connect-profile', '123-456').returncode, 0)
        self.assertEqual((self.base/'record').read_text().strip(), 'connection up uuid 123-456')
        self.assertNotEqual(self.run_action('connect-profile', 'unknown').returncode, 0)
    def test_wifi_password_stdin_not_arguments(self):
        self.assertEqual(self.run_action('wifi', 'Home', 'AA:BB:CC:DD:EE:FF', input='test-only-password\n').returncode, 0)
        self.assertEqual((self.base/'record').read_text().strip(), '--ask device wifi connect Home bssid AA:BB:CC:DD:EE:FF')
        self.assertEqual((self.base/'record.stdin').read_text(), 'test-only-password\n')
        self.assertNotEqual(self.run_action('wifi', 'Home', 'unknown').returncode, 0)
    def test_microphone_and_media(self):
        self.assertEqual(self.run_action('mic-mute').returncode, 0)
        self.assertEqual((self.base/'record').read_text().strip(), 'set-source-mute @DEFAULT_SOURCE@ toggle')
        self.assertEqual(self.run_action('play-pause').returncode, 0)
        self.assertEqual((self.base/'record').read_text().strip(), 'play-pause')
if __name__ == '__main__': unittest.main()