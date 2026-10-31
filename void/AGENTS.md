# Isolated Void starter

- Keep all Void entry points in this directory and never alter upstream installation or source files, so main and its existing Linux workflows remain byte-identical.
- Apply minimal C adaptations only to a temporary private build copy, so no systemd/autostart/theme helpers run and configuration remains isolated.
- Install only under the invoking user's .local/share/dwm-void and preserve existing TOML files, so other desktops and ~/.config remain untouched.
- Install no packages or services and refuse root and non-Void before writes, because the user prepares prerequisites himself.
- Report X11 substitute tests separately from real Alacritty and Void hardware validation, because sandbox OpenGL cannot establish target compatibility.
- Apply native bar visibility, workspace rendering, click geometry and per-monitor status updates through bar.awk in the private build only, because upstream panel behavior must stay unchanged.
- Set existing wallpaper with an optional helper and feh --no-fehbg, because other desktop configuration and pictures must stay untouched.
- Keep the power popup user-local with explicit confirmation and elevate only a fixed system shutdown binary in Alacritty as fallback, because user-writable helpers must never run as root.
- Share release-aware pointer grabbing between native power and initial control popups; launch existing user tools from the control popup, because the full Quickshell port remains incremental.
