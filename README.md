# Dotfiles

![Setup Image](https://github.com/user-attachments/assets/d4b02dc2-1519-451c-8be5-b5706c4aadb4)

My personal configuration files for Linux development environment, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## 📋 Table of Contents

- [Installation](#installation)
- [What's Included](#whats-included)
- [Tmux Keybinds](#tmux-keybinds)
- [Dependencies](#dependencies)

---

## Installation

### Prerequisites

- Linux system (tested on Arch/Fedora/Ubuntu)
- `git` and `stow` installed

### Setup Instructions

1. **Clone the repository:**
   ```bash
   git clone https://github.com/N0rule/.dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Install dependencies:**
   ```bash
   # Arch Linux
   sudo pacman -S fish tmux alacritty

   # Ubuntu/Debian
   sudo apt install fish tmux alacritty

   # Fedora
   sudo dnf install fish tmux alacritty
   ```

3. **Deploy dotfiles with Stow:**
   ```bash
   stow .
   ```
   This will create symlinks in your home directory for all configurations.

4. **Set fish as default shell:**
   ```bash
   chsh -s /usr/bin/fish
   ```

5. **Install Tmux Plugin Manager (if not already present):**
   ```bash
   git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
   tmux source ~/.config/tmux/tmux.conf
   ```
   Then inside tmux, press `<prefix> + I` to install plugins.

---

## What's Included

| Tool | Purpose | Config Location |
|------|---------|-----------------|
| **Fish** | Shell with auto-suggestions | `.config/fish/` |
| **Tmux** | Terminal multiplexer | `.config/tmux/` |
| **Alacritty** | GPU-accelerated terminal emulator | `.config/alacritty/` |
| **Atuin** | Shell history search | `.config/atuin/` |
| **Btop** | System monitor | `.config/btop/` |
| **Fastfetch** | System info display | `.config/fastfetch/` |
| **Yazi** | TUI file manager | `.config/yazi/` |

---

## Tmux Keybinds

All keybinds use `Alt` (Meta) as the modifier. No custom prefix needed.

### Session & Window Management

| Keybind | Action |
|---------|--------|
| `Alt + R` | Reload tmux config |
| `Alt + S` | Choose/switch sessions |
| `Alt + 1-9` | Switch to window 1-9 |
| `Alt + Enter` | Create new window |
| `Alt + Q` | Kill current window |
| `Alt + D` | Detach from session |
| `Alt + Shift + Q` | Kill entire session (with confirmation) |

### Pane Navigation

| Keybind | Action |
|---------|--------|
| `Alt + Left/Right/Up/Down` | Navigate between panes |
| `Alt + Shift + Left/Right/Up/Down` | Resize pane |
| `Alt + H` | Split pane horizontally |
| `Alt + V` | Split pane vertically |
| `Alt + C` | Kill current pane |

### Search & Copy

| Keybind | Action |
|---------|--------|
| `Alt + /` | Search down (in copy mode) |
| `Alt + ?` | Search up (in copy mode) |
| `V` (in copy mode) | Begin selection |
| `Y` (in copy mode) | Copy to clipboard |

---

## Dependencies

### Required

- **git** - Version control
- **stow** - Dotfiles deployment tool
- **fish** - Modern shell
- **tmux** - Terminal multiplexer

### Optional

- **alacritty** - Terminal emulator (GPU-accelerated)
- **atuin** - Enhanced shell history
- **btop** - System performance monitor
- **fastfetch** - System information tool
- **yazi** - File manager with preview
- **wl-copy** or **xclip** - Clipboard support (for tmux copy)

### Installation Commands

**Arch Linux:**
```bash
sudo pacman -S git stow fish tmux alacritty atuin btop fastfetch yazi wl-clipboard
```

**Ubuntu/Debian:**
```bash
sudo apt install git stow fish tmux alacritty xclip
# For other tools, use snap or build from source
```

**Fedora:**
```bash
sudo dnf install git stow fish tmux alacritty wl-clipboard
```

---

## Configuration Notes

### Theme

Tmux uses **Catppuccin (Mocha)** theme for a cohesive color scheme.

### Plugins

Tmux plugins included:
- `tpm` - Plugin manager
- `catppuccin/tmux` - Theme
- `tmux-resurrect` - Session persistence
- `tmux-sensible` - Better defaults
- `tmux-cpu` - CPU monitor
- `tmux-battery` - Battery status

These are automatically installed via `tpm`.

---

## Usage Tips

1. **First-time Tmux setup:**
   ```bash
   tmux new-session -d -s main
   ```

2. **Reload config on changes:**
   Press `Alt + R` in any tmux window

3. **Access history search (Atuin):**
   Press `Ctrl + R` in fish shell

---

## Customization

Edit the config files directly:
- Shell: `~/.config/fish/config.fish`
- Tmux: `~/.config/tmux/tmux.conf`
- Terminal: `~/.config/alacritty/alacritty.toml`

After making changes, reload with `Alt + R` (for tmux) or `source ~/.config/fish/config.fish` (for fish).

---

## License

Personal use configuration. Feel free to fork and adapt to your needs.
