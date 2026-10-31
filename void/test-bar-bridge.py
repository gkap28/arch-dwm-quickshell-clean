"""Run inside the Void session: python3 void/test-bar-bridge.py.
Checks monitor-directed workspace changes and restores original desktops.
"""
import json, os, pathlib, subprocess, unittest
class BridgeTests(unittest.TestCase):
    def test_each_monitor_switches_independently(self):
        bridge=str(pathlib.Path.home()/'.local/share/dwm-void/bar-bridge')
        watcher=subprocess.Popen([bridge,'watch'],stdout=subprocess.PIPE,text=True)
        try:
            initial=json.loads(watcher.stdout.readline())['monitors']
            self.assertGreaterEqual(len(initial),1)
            for original in initial:
                target=(original['desktop']+1)%9
                subprocess.run([bridge,'view',str(target),str(original['x']),str(original['y'])],check=True)
                while True:
                    state=json.loads(watcher.stdout.readline())['monitors']
                    row=next(m for m in state if m['x']==original['x'] and m['y']==original['y'])
                    if row['desktop']==target:break
                self.assertEqual(row['desktop'],target)
                for other in initial:
                    if other['x']==original['x'] and other['y']==original['y']:continue
                    self.assertEqual(next(m['desktop'] for m in state if m['x']==other['x'] and m['y']==other['y']),other['desktop'])
                subprocess.run([bridge,'view',str(original['desktop']),str(original['x']),str(original['y'])],check=True)
        finally:
            watcher.terminate();watcher.wait(timeout=5)
            if 'initial' in locals():
                for m in initial:subprocess.run([bridge,'view',str(m['desktop']),str(m['x']),str(m['y'])],check=True)
if __name__=='__main__':unittest.main()
