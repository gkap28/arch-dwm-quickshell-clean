"""Private dwm/Quickshell clicks; no physical monitors or system actions."""
import importlib.util
import pathlib
import subprocess
import time
import unittest

spec = importlib.util.spec_from_file_location('starter', pathlib.Path(__file__).with_name('test-starter.py'))
starter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(starter)
import os
starter.ROOT = pathlib.Path(os.environ.get('VOID_TEST_SOURCE_ROOT', starter.ROOT))

class CenterWindowTests(starter.StarterTests):
    def test_widgets_reload_and_fullscreen_facts(self):
        terminal = self.bin/'alacritty'; terminal.write_text('#!/bin/sh\nexit 0\n'); terminal.chmod(0o755)
        result = self.install(); self.assertEqual(result.returncode, 0, result.stderr)
        data = self.home/'.local/share/dwm-void'
        runtime = self.base/'runtime'; runtime.mkdir(mode=0o700)
        env = {**self.env, 'DISPLAY': ':186', 'XDG_RUNTIME_DIR': str(runtime), 'QT_QPA_PLATFORM': 'xcb', 'QT_QUICK_BACKEND': 'software'}
        processes = []
        captures = pathlib.Path('/tmp/center-test/screenshots'); captures.mkdir(parents=True, exist_ok=True)
        log = open(self.base/'center.log', 'w')
        def command(*args): return subprocess.run(args, env=env, capture_output=True, text=True, check=True).stdout
        def click(x, y):
            command('xdotool', 'mousemove', str(x), str(y))
            command('xdotool', 'click', '1'); time.sleep(.5)
        def capture(name): command('magick', 'import', '-window', 'root', str(captures/name))
        try:
            processes.append(subprocess.Popen(['Xvfb', ':186', '-screen', '0', '1280x800x24', '-nolisten', 'tcp'], env=env, stdout=log, stderr=log))
            for _ in range(100):
                if subprocess.run(['xprop','-root'],env=env,capture_output=True).returncode == 0: break
                time.sleep(.05)
            wm = subprocess.Popen([str(data/'dwm')],env=env,stdout=log,stderr=log); processes.append(wm); time.sleep(.5)
            shell = subprocess.Popen(['quickshell','--path',str(data/'quickshell/shell.qml')],env=env,stdout=log,stderr=log); processes.append(shell); time.sleep(2)
            click(14,14); capture('main.png')
            self.assertRegex(command('xwininfo','-root','-tree'),r'276x\d+\+6\+28 ')
            # A press inside keeps the menu; an outside desktop press closes it.
            click(100,50)
            self.assertRegex(command('xwininfo','-root','-tree'),r'276x\d+\+6\+28 ')
            click(600,600); capture('center-dismissed.png')
            self.assertNotRegex(command('xwininfo','-root','-tree'),r'276x\d+\+6\+28 ')
            click(1260,14)
            self.assertRegex(command('xwininfo','-root','-tree'),r'276x\d+\+996\+28 ')
            click(1100,50)
            self.assertRegex(command('xwininfo','-root','-tree'),r'276x\d+\+996\+28 ')
            click(600,600); capture('power-dismissed.png')
            self.assertNotRegex(command('xwininfo','-root','-tree'),r'276x\d+\+996\+28 ')
            click(14,14)
            click(100,180); capture('widgets.png')
            for y, key in [(90,'power'),(120,'volume'),(150,'network'),(180,'layout'),(210,'seconds')]:
                click(150,y)
                expected = 1 if key == 'seconds' else 0
                self.assertIn(f'{key}={expected}\n', (data/'config/center.conf').read_text())
            capture('widgets-changed.png')
            command('xdotool','key','Escape'); time.sleep(.3)
            command(str(data/'bar-bridge'),'reload'); time.sleep(.5)
            self.assertIsNone(wm.poll(), 'Reload keeps this dwm process alive')
            command('sh', str(data/'center-action.sh'), 'reload-quickshell'); time.sleep(2)
            self.assertIsNone(shell.poll(), 'Reload keeps this shell instance alive')
            click(14,14); capture('reloaded.png'); command('xdotool','key','Escape')
            info = subprocess.Popen(['sh',str(data/'control-action.sh'),'system-info','0','0'],env=env,stdout=log,stderr=log); processes.append(info); time.sleep(2)
            window = command('xdotool','search','--onlyvisible','--name','^Void System Info$').split()[0]
            self.assertIn('_NET_WM_STATE_FULLSCREEN', command('xprop','-id',window,'_NET_WM_STATE'))
            capture('system-info.png')
            command('xdotool','key','Escape'); time.sleep(.3)
            self.assertFalse((self.home/'.config').exists())
            log.flush(); text=(self.base/'center.log').read_text()
            self.assertNotIn('Failed to load configuration', text)
            self.assertNotIn('TypeError', text)
        finally:
            for process in reversed(processes):
                if process.poll() is None: process.terminate(); process.wait(timeout=5)
            log.close()

if __name__ == '__main__': unittest.main(defaultTest='CenterWindowTests.test_widgets_reload_and_fullscreen_facts')