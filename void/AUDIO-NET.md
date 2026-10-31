# Void audio and NET modules

Right side order: network, volume, power. Nord pill geometry follows the Titus reference (26 height, radius 6, 4 spacing); symbols are drawn, no Nerd Font required. Clicking opens separate Nord popups for the clicked monitor. Volume has slider, mute and settings; wheel changes volume by 5 percent. Network shows WLAN/cable/disconnected and opens existing nm-connection-editor, or nmtui in Alacritty. Close via the x or by clicking the same pill again.

Reads existing pactl and nmcli; without nmcli reads /sys/class/net link state (not an Internet-connectivity check). Missing audio shows unavailable; no services, config files or packages are installed. Audio settings require existing pavucontrol. Other desktops/main remain unchanged.

Validation: real Quickshell under single-screen Xvfb: both popup clicks and settings dispatch to harmless test programs passed; six starter/dual-simulated-monitor tests passed separately. Hermetic audio/network status and bounded volume-action tests passed. Actual sound/network changes on Void, dual physical Qt outputs and Alacritty remain for Georg to check.

Update: git pull; sh void/start.sh --install; save work, Super+Shift+Q, log in again.
