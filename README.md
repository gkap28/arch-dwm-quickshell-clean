# gkap28-arch-dwm-quickshell

My personal Arch Linux X11 desktop environment based on
[dwm-titus](https://github.com/ChrisTitusTech/dwm-titus), extended and adapted
for my own workflow.

This repository is my own development and adaptation. It is not the original
`dwm-titus` project.

## Features

- dwm-based X11 desktop
- Quickshell integration
- Current dwm-titus Control Center and Settings adapted for Arch Linux
- Pacman updates with optional paru/yay support in a visible terminal
- Dual-monitor support
- Workspace-to-monitor mapping
- Custom themes and desktop styling
- Custom keybindings and window rules
- Wallpaper handling
- XDG autostart integration
- User-level systemd graphical-session integration
- Polkit authentication agent support
- Picom compositor integration
- Input-device configuration and persistence
- Meslo / Nerd Font aliases
- User shell configuration
- Installation preserving existing user configuration
- Migration support for older dwm-titus setups

## Installation
Clone the repository:

git clone https://github.com/gkap28/arch-dwm-quickshell-clean.git
cd arch-dwm-quickshell-clean

Build and install:

make
sudo make install
make install-user

The install-user target must be run as the normal user, not with sudo.

Existing user configuration is preserved where possible.

Configuration

User configuration is installed below:

~/.config/

The repository also keeps its local configuration and scripts under:

~/.local/share/dwm-titus/

The installer is designed to seed configuration without unnecessarily
overwriting existing personal settings.

Development

This is an ongoing personal Arch Linux project.

The goal is to keep the desktop lightweight, understandable and easy to
modify while continuing to develop and improve the integration of dwm,
Quickshell and the surrounding X11 desktop components.

Credits

This project is based on the work of Chris Titus Tech and his
dwm-titus project.

The original project provided the foundation for this desktop.

This repository is our Arch Linux adaptation and development, including
Quickshell integration, themes, dual-monitor configuration,
workspace-to-monitor mapping, keybindings, wallpaper handling,
and additional desktop tooling.

Many thanks to Chris Titus Tech for the original work and inspiration.