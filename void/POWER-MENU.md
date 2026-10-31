# Void bar clicks and power menu

After git pull, run sh void/start.sh --install as your normal user. Save work and restart the desktop with Super+Shift+Q. Run sh void/start.sh from the console if it does not restart automatically.

Left-click workspaces 1-9 independently on each monitor. Native click handling is in the private Void build; your existing hotkeys.toml is not changed.

The [O] control at the right edge opens a small Nord X11 menu with the same five actions as the Titus menu: reboot, logout, lock, suspend, shutdown. It is not yet the full Quickshell menu. All but lock ask for confirmation. Escape or an outside click dismisses it. Lock needs slock or i3lock. Suspend needs elogind/loginctl. Reboot/shutdown first use loginctl; otherwise Alacritty asks for sudo credentials for a fixed system shutdown binary. No services or permission policies are installed. Only the invoking user's dwm session is terminated by logout.

Tests: workspace mouse clicks on two simulated Xinerama displays; popup opens from the right bar, Escape cancels without action, confirmation invokes a test stub rather than rebooting. Safety, workspace independence, status, hotkeys, monitors and wallpaper regressions passed. Actual Void power operations must still be checked by Georg; real Alacritty graphics are not tested in this sandbox.
