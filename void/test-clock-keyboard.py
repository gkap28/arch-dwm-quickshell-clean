import importlib.util, os, pathlib, subprocess, time, unittest

HERE = pathlib.Path(__file__).parent
spec = importlib.util.spec_from_file_location('starter', HERE/'test-starter.py')
starter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(starter)
starter.ROOT = pathlib.Path(os.environ.get('VOID_TEST_SOURCE_ROOT', starter.ROOT))

class ClockTests(unittest.TestCase):
    def test_requested_german_clock(self):
        text = subprocess.check_output(['sh', '-c', '. "$1"; clock_text 0 01 11 13.40', 'sh', str(HERE/'clock-format.sh')], text=True)
        self.assertEqual(text.strip(), 'So 01 Nov- 13.40')

class KeyboardTests(starter.StarterTests):
    def test_click_cycles_real_us_de_gr_group(self):
        terminal = self.bin/'alacritty'; terminal.write_text('#!/bin/sh\nexit 0\n'); terminal.chmod(0o755)
        result = self.install(); self.assertEqual(result.returncode, 0, result.stderr)
        data = self.home/'.local/share/dwm-void'
        runtime = self.base/'runtime'; runtime.mkdir(mode=0o700)
        env = {**self.env, 'DISPLAY':':187', 'XDG_RUNTIME_DIR':str(runtime), 'QT_QPA_PLATFORM':'xcb', 'QT_QUICK_BACKEND':'software'}
        log = open(self.base/'flow.log', 'w'); processes = []
        def command(*args): return subprocess.check_output(args, env=env, text=True).strip()
        try:
            processes.append(subprocess.Popen(['Xvfb', ':187', '-screen','0','1280x800x24','-nolisten','tcp'],env=env,stdout=log,stderr=log))
            for _ in range(100):
                if subprocess.run(['xprop','-root'],env=env,capture_output=True).returncode == 0: break
                time.sleep(.05)
            processes.append(subprocess.Popen([str(data/'dwm')],env=env,stdout=log,stderr=log)); time.sleep(.5)
            command('setxkbmap','-option','compose:ralt','-layout','us,de,gr')
            processes.append(subprocess.Popen(['quickshell','--path',str(data/'quickshell/shell.qml')],env=env,stdout=log,stderr=log)); time.sleep(2)
            command('xsetroot','-name','So 01 Nov- 13.40'); time.sleep(.5)
            self.assertIn('1280x28', command('xwininfo','-root','-tree'), (self.base/'flow.log').read_text())
            self.assertEqual(command(str(data/'keyboard-bridge'),'status'),'US')
            for expected in ['DE','GR','US']:
                # Keyboard module is immediately before NET/audio/power, fixed width.
                command('xdotool','mousemove','1088','14'); command('xdotool','click','1'); time.sleep(.7)
                self.assertEqual(command(str(data/'keyboard-bridge'),'status'), expected)
            self.assertIn('compose:ralt', command('setxkbmap','-query'))
            pathlib.Path('/tmp/void-font-check').mkdir(exist_ok=True)
            command('magick','import','-window','root','-crop','1280x28+0+0','/tmp/void-font-check/bar.png')
            self.assertNotIn('Failed to load', (self.base/'flow.log').read_text())
            self.assertNotIn('is not defined', (self.base/'flow.log').read_text())
            print('Real Quickshell click: US → DE → GR → US; XKB options preserved. Font/clock bar captured; no real Void hardware or Alacritty.')
        finally:
            for p in reversed(processes):
                if p.poll() is None: p.terminate(); p.wait(timeout=5)
            log.close()

if __name__ == '__main__': unittest.main(defaultTest=['ClockTests','KeyboardTests.test_click_cycles_real_us_de_gr_group'])