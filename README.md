# Dotfiles

My personal collection of dotfiles for a customized Linux desktop environment. Feel free to use them, at your own risk! 👻

## Applications

This repository contains configuration files for the following applications:

### Window Managers/Desktop Environment
- [Hyprland](https://hyprland.org/) - A dynamic tiling Wayland compositor
- [i3](https://i3wm.org/) - A tiling window manager

### Terminal Emulators
- [Alacritty](https://alacritty.org/) - A cross-platform, GPU-accelerated terminal emulator
- [Kitty](https://sw.kovidgoyal.net/kitty/) - The fast, feature-rich, GPU based terminal emulator

### System Tools and Utilities
- [Hyprlock](https://github.com/hyprwm/hyprlock) - Hyprland's screen locker
- [Hyprpaper](https://github.com/hyprwm/hyprpaper) - Wallpaper utility for Hyprland
- [Picom](https://github.com/yshui/picom) - A lightweight compositor for X11
- [Waybar](https://github.com/Alexays/Waybar) - Highly customizable Wayland bar
- [Polybar](https://polybar.github.io/) - A fast and easy-to-use status bar
- [Tmux](https://github.com/tmux/tmux) - Terminal multiplexer

### Application Launchers
- [Rofi](https://github.com/davatorium/rofi) - A window switcher, application launcher
- [Wofi](https://hg.sr.ht/~scoopta/wofi) - A launcher/menu program for wlroots based wayland compositors

### Shell and Editor
- [Zsh](https://www.zsh.org/) - Z shell configuration
- [Neovim](https://neovim.io/) - Hyperextensible Vim-based text editor
- [Starship](https://starship.rs/) - The minimal, blazing-fast, and infinitely customizable prompt

## Installation

Clone this repository to your home directory:

```bash
git clone https://github.com/olejaco/dotfiles.git ~/.dotfiles
```

### Using GNU Stow

This repository is organized to work with [GNU Stow](https://www.gnu.org/software/stow/), a symlink farm manager. It makes it easy to maintain dotfiles by creating appropriate symbolic links.

1. First, install GNU Stow:
   ```bash
   # On Ubuntu/Debian
   sudo apt install stow
   
   # On Arch Linux
   sudo pacman -S stow
   
   # On Fedora
   sudo dnf install stow
   ```

2. Navigate to the dotfiles directory:
   ```bash
   cd ~/.dotfiles
   ```

3. Use Stow to create symlinks. For example, to set up Neovim configuration:
   ```bash
   stow nvim
   ```

   This will create the appropriate symlinks in your home directory.

4. You can stow multiple configurations at once:
   ```bash
   stow hyprland waybar kitty zshrc
   ```

To remove the symlinks for a package:
```bash
stow -D nvim
```

To simulate what would happen (dry-run):
```bash
stow -n nvim
```

## Structure

The repository is organized by application, with each directory containing the respective configuration files:

```
.
├── alacritty/     # Alacritty terminal configuration
├── backgrounds/    # Wallpapers and background images
├── hyprland/      # Hyprland compositor configuration
├── hyprlock/      # Screen locker configuration
├── hyprpaper/     # Wallpaper utility configuration
├── i3/            # i3 window manager configuration
├── kitty/         # Kitty terminal configuration
├── nvim/          # Neovim configuration
├── picom/         # Picom compositor configuration
├── polybar/       # Polybar configuration
├── rofi/          # Rofi configuration
├── starship/      # Starship prompt configuration
├── styles/        # Theme configurations
├── tmux/          # Tmux configuration
├── waybar/        # Waybar configuration
├── wofi/          # Wofi configuration
└── zshrc/         # Zsh configuration
```

## License

Feel free to use and modify these configurations as you see fit.
