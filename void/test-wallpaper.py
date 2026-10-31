import os, pathlib, subprocess, tempfile, unittest
SCRIPT = pathlib.Path(__file__).with_name('wallpaper.sh')

class WallpaperTests(unittest.TestCase):
    def test_named_wallpapers_follow_xinerama_order(self):
        with tempfile.TemporaryDirectory() as tmp:
            home=pathlib.Path(tmp); pictures=home/'Pictures/backgrounds'; pictures.mkdir(parents=True)
            for name in ['nord2560.png', 'arch-dwm-avatar.png']: (pictures/name).write_bytes(b'keep')
            tools=home/'bin'; tools.mkdir()
            scripts={
                'feh': 'printf "%s\\n" "$@" > "$HOME/arguments"',
                'xrandr': "printf 'DisplayPort-2 connected 1920x1080+2560+0\\nHDMI-A-0 connected primary 2560x1080+0+0\\n'",
                'xdpyinfo': "printf '  head #0: 1920x1080 @ 2560,0\\n  head #1: 2560x1080 @ 0,0\\n'"
            }
            for name, body in scripts.items():
                p=tools/name; p.write_text('#!/bin/sh\n'+body+'\n'); p.chmod(0o755)
            env={**os.environ, 'HOME': tmp, 'PATH': str(tools)+':/usr/bin:/bin'}
            result=subprocess.run(['sh',str(SCRIPT)],env=env,capture_output=True)
            self.assertEqual(result.returncode,0)
            self.assertEqual((home/'arguments').read_text().splitlines(), ['--no-fehbg','--bg-fill',str(pictures/'arch-dwm-avatar.png'),str(pictures/'nord2560.png')])
            # HDMI still gets its own image when the DisplayPort is absent.
            (tools/'xrandr').write_text("#!/bin/sh\necho 'HDMI-A-0 connected primary 2560x1080+0+0'\n")
            (tools/'xdpyinfo').write_text("#!/bin/sh\necho '  head #0: 2560x1080 @ 0,0'\n")
            subprocess.run(['sh',str(SCRIPT)],env=env,check=True)
            self.assertEqual((home/'arguments').read_text().splitlines(), ['--no-fehbg','--bg-fill',str(pictures/'nord2560.png')])
            self.assertFalse((home/'.fehbg').exists())
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