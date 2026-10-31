# Nord Void update

Workspace buttons match the Titus default geometry: 22x22, radius 6, 1px selected/hover border #81A1C1, spacing 1; idle buttons show the Nord bar background. Selected labels are bold. Other desktop themes and upstream sources remain unchanged.

Control center > Programme opens a user-local Quickshell launcher with installed DesktopEntries, search, arrow selection, Enter/click to launch and Escape to close. The popup passes monitor coordinates, not assumed screen indexes. It is installed only in ~/.local/share/dwm-void/quickshell.

Installed Picom starts with the Void session, using existing settings. Logs: ~/.local/share/dwm-void/picom.log. No packages/config files are installed and only this session's child is stopped; a different compositor is never killed.

Update in the existing checkout: git pull; sh void/start.sh --install. Save work, Super+Shift+Q, log in again.

Validation: six Quickshell/starter X11 tests passed under Xvfb, plus Picom process-stub regression. Search actually launched a test DesktopEntry. Xterm substituted for Alacritty; Qt/Xvfb exposes one logical screen although dwm's two monitor geometries were simulated. Real Void graphics, actual Picom rendering, and dual physical Qt outputs await Georg's check.
