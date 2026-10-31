import os, pathlib, subprocess, tempfile, unittest
SCRIPT = pathlib.Path(__file__).with_name('wallpaper.sh')

class WallpaperTests(unittest.TestCase):
    def test_existing_picture_with_spaces_and_no_settings_written(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = pathlib.Path(tmp)
            pictures = home/'Pictures/backgrounds'; pictures.mkdir(parents=True)
            image = pictures/'my nord image.png'; image.write_bytes(b'unchanged')
            bin = home/'bin'; bin.mkdir()
            feh = bin/'feh'
            feh.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$HOME/arguments"\n')
            feh.chmod(0o755)
            result = subprocess.run(['sh', str(SCRIPT)], env={**os.environ, 'HOME': tmp, 'PATH': str(bin)+':/usr/bin:/bin'})
            self.assertEqual(result.returncode, 0)
            self.assertEqual((home/'arguments').read_text().splitlines(), ['--no-fehbg', '--bg-fill', str(image)])
            self.assertEqual(image.read_bytes(), b'unchanged')
            self.assertFalse((home/'.fehbg').exists())

    def test_absent_image_does_not_block_session(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(['sh', str(SCRIPT)], env={**os.environ, 'HOME': tmp}, capture_output=True)
            self.assertEqual(result.returncode, 0)

if __name__ == '__main__': unittest.main()
