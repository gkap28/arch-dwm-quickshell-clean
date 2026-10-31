# Initial Void control center

Update: git pull; sh void/start.sh --install (normal user). Save work, Super+Shift+Q, then sh void/start.sh from the console if necessary.

Georg's uploaded logo is resized for the native bar and appears before tags on each monitor. Left-click opens the initial control menu on that monitor. It launches existing user tools: Alacritty, Thunar, hotkeys editor, ARandR, pavucontrol, nmtui, wallpaper restore and power menu. These tools must be installed by the user. This is a first menu, not yet the full Quickshell control center or per-monitor wallpaper selector.

Bindings live in ~/.local/share/dwm-void/config/hotkeys.toml. The menu opens that exact file using EDITOR (vi if unset). Existing configuration is preserved.

Both native popups wait for the initiating button to be released, retry grabs briefly and act on release. This addresses the held-click popup exit. Tested on Xvfb with simulated Xinerama displays: hold initial mouse press 0.5 seconds, release, power menu stays open; confirmation/cancellation; logo opens control menu at x=10 and x=2570; selecting hotkeys invokes the test helper. Screenshot shows uploaded logo before 1-9 on both bars. Real Void graphics/menu confirmation remains Georg's hardware test.
