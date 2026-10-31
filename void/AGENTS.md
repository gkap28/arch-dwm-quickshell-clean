# Isolated Void starter

- Keep all Void entry points in this directory and never alter upstream installation or source files, so main and its existing Linux workflows remain byte-identical.
- Apply minimal C adaptations only to a temporary private build copy, so no systemd/autostart/theme helpers run and configuration remains isolated.
- Install only under the invoking user's .local/share/dwm-void and preserve existing TOML files, so other desktops and ~/.config remain untouched.
- Install no packages or services and refuse root and non-Void before writes, because the user prepares prerequisites himself.
- Report X11 substitute tests separately from real Alacritty and Void hardware validation, because sandbox OpenGL cannot establish target compatibility.
- Apply native bar visibility, workspace rendering, click geometry and per-monitor status updates through bar.awk in the private build only, because upstream panel behavior must stay unchanged.
- Set existing wallpaper with an optional helper and feh --no-fehbg, because other desktop configuration and pictures must stay untouched.
