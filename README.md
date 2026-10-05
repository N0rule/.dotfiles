![Setup Image](https://github.com/user-attachments/assets/d4b02dc2-1519-451c-8be5-b5706c4aadb4)
# CachyOS · Niri · native Noctalia
Personal dotfiles for CachyOS, Niri and native C++ Noctalia v5, refreshed from
this machine on 2026-10-05. The installer is a **Fish script** using standard
Linux tools. Python, GNU Stow and an extra UI package are not required.

## Interactive setup

On an installed CachyOS system with a working network, run as your normal user:

```fish
sudo pacman -Syu --needed git fish
git clone https://github.com/N0rule/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
fish --no-config setup.fish
```

The terminal UI lets you choose:

1. Packages and configs, packages only, or configs only.
2. Individual packages to install (including the native `noctalia-git` AUR package).
3. Individual application configs to deploy.
4. Wallpaper and profile image independently; **both are off by default**.
5. Optional HP EliteBook button mappings, **off by default**. Bongocat and its
   keyd keyboard setup are automatically included with the Noctalia config.
6. Final action: **1. Apply (default)**, **2. Test apply**, **3. Cancel**.
   Enter selects Apply. Test apply prints the plan without changing packages,
   configs or services.

In each checklist, enter numbers to toggle items, `a` for all, `n` for none,
Enter to finish, or `q` to cancel. For example, `2 5` toggles rows 2 and 5.
Nothing is installed or copied before the final action screen. Choose `1` or
press Enter to apply; choose `2` to preview without making changes.
Keep existing app settings by deselecting its config. Most package and config
selections are independent. Noctalia includes Bongocat's `keyd` and `evtest`
dependencies whenever package installation is selected; these are added even
if individually deselected. Applying the Noctalia config also deploys the keyd
profile and device-access rule and enables/restarts keyd.

Package installation uses `sudo pacman -Syu --needed`, followed by
`paru -S --needed` for selected AUR packages. Review the normal package prompts
and AUR build files. If AUR packages are selected, include `paru` or have it
installed already. Available packages are in [packages/repo.txt](packages/repo.txt)
and [packages/aur.txt](packages/aur.txt). This includes desktop and terminal
utilities; development, gaming and music apps are outside the installer.

Native Noctalia runs as `noctalia` and uses `noctalia msg` bindings. Its project
is [noctalia-dev/noctalia](https://github.com/noctalia-dev/noctalia); this setup
uses `noctalia-git`, rather than the legacy Quickshell shell. The source system
used Niri `26.04-1.1` and Noctalia `5.1.0.r5545.ge4eb0ff97-1`.
Installation gets current packages. Validate compatibility after updates:

```fish
fish --no-config setup.fish --check
```

The Niri config uses CachyOS blur settings, which can differ from other builds.

## Wallpaper and profile image

They are optional and not required for Niri or Noctalia. If selected, the script
copies the corresponding image into `~/Pictures/Dotfiles/` and includes its
paths in the deployed Noctalia config. If skipped, it omits that image's paths
and settings, keeping Noctalia's defaults or existing GUI overrides. Wallpaper
and profile image can be selected separately. No images are deleted when you
later skip them. The repo's source TOML retains the complete snapshot; filtering
happens only during deployment.

## Command-line use

`--no-config` skips Fish startup files, so user aliases and integrations cannot
interfere with setup. You can also run `./setup.fish`; its executable shebang
already includes `--no-config`.

```fish
# Preview all configs; no images or package changes.
fish --no-config setup.fish --dry-run

# Preview just the desktop packages and configs, with the wallpaper.
fish --no-config setup.fish --install --apply --dry-run \
    --packages niri,noctalia-git,paru \
    --configs niri,noctalia --wallpaper

# Deploy terminal configs only.
fish --no-config setup.fish --apply --configs fish,alacritty,tmux

# List available choices or read the help.
fish --no-config setup.fish --list
fish --no-config setup.fish --help
```

Explicit command-line `--install` and `--apply` execute directly; add
`--dry-run` to preview. Package/config lists default to all when omitted.
Use `--packages none` or `--configs none` for an empty list.
`--wallpaper` and `--avatar` are independent image options.
`--home /path/to/existing/test-home` changes the deployment destination;
package installation still affects the system. The script never changes the
login shell. Applying the Noctalia config includes keyd system setup and
enables/restarts its service. Config-only deployment requires installed keyd
and evtest; select package installation too on a fresh machine.

## Config deployment and backups

| Config | Purpose |
| --- | --- |
| `niri` | Input, layout, rules, shortcuts, startup and theme |
| `noctalia` | Native bar, idle, theme and plugin preferences |
| `fish` | CachyOS shell, Atuin, zoxide, fzf and aliases |
| `alacritty` | Transparent terminal with FiraCode Nerd Font |
| `tmux` | Alt bindings, Catppuccin and session persistence |
| `atuin`, `btop`, `fastfetch`, `yazi` | Terminal tools and themes |

Only selected configs are copied. Existing identical files are skipped, and
unrelated files are preserved. Conflicts are backed up under
`~/.local/state/dotfiles-backups/<timestamp>/`. Directory symlinks are backed
up and detached before changed files are written, preserving their contents
and keeping the linked repository untouched. Backup symlinks have a `.symlink`
suffix and use absolute targets so they still work after moving. Stop the
affected app before restoring files from the printed backup path.

Existing identical Stow links remain in place; changed links may become local
copies. Edit repo files and rerun the script to deploy updates. Deployment
honors `XDG_CONFIG_HOME` when it is inside your home directory. Unset
`NOCTALIA_CONFIG_HOME` before deploying this snapshot. Do not run `stow .`:
this repo also includes the installer, docs, manifests and optional assets.

Yazi's `flavors/noctalia.yazi/tmtheme.xml` is part of the selected Yazi config
and is copied along with `flavor.toml`. Yazi uses it for syntax highlighting
in file previews; no Stow command or extra installation step is needed.

## Keyd, Bongocat and HP EliteBook buttons

**Bongocat is included by default with Noctalia.** Applying the Noctalia config
automatically configures keyd's virtual keyboard and device permissions.
Package installation with Noctalia includes `keyd` and `evtest`. The default
profile passes keys through and contains no HP button mappings.

Choose **elitebook-buttons** only for this HP EliteBook. It uses the existing
three remaps: monitor button opens the terminal, answer
button takes a region screenshot, and hangup button closes the window.
The captured profile uses a wildcard device match, as on the source system;
other models can emit different chords, so check `keyd monitor` before using it.

```fish
# Preview generic keyd/Bongocat setup without HP remaps.
fish --no-config setup.fish --apply --configs noctalia --dry-run

# Apply generic keyd setup (requires installed keyd and evtest).
fish --no-config setup.fish --apply --configs noctalia

# Explicitly use the HP EliteBook profile instead.
fish --no-config setup.fish --apply --configs noctalia --elitebook
```

Applying keyd setup installs the selected profile as `/etc/keyd/default.conf`
and a `70-keyd-bongocat.rules` udev rule, then validates the installed configs,
reloads rules and enables/restarts keyd. Existing files are backed up under
`/var/backups/dotfiles/<timestamp>/`; other keyd config files are preserved.
The stable device path is `/dev/input/by-id/keyd-virtual-keyboard`. The rule
grants the active local session read access only to that virtual device; it
does not add the user to the broad `input` group. A new login may be needed
for the session permissions to take effect.

The Noctalia config includes the `cat_2` widget's virtual-keyboard input path.
Existing GUI overrides still take precedence. Deselect Noctalia if you want
to skip its config and automatic keyd setup. The `--keyd` flag remains available
for standalone backend setup. Bongocat can also read other input devices directly;
keyd is the chosen backend for these dots, rather than a plugin requirement.
The plugin requires `evtest` and permission to read its selected devices.
See the [plugin documentation](https://github.com/noctalia-dev/official-plugins/blob/main/bongocat/README.md).

For a test deployment, combine `--home <test-home>` with
`--system-root <test-system-root>`. Both directories must exist. This stages
system files under the test root and does not run sudo, restart services or
touch live devices. The script refuses `--keyd --home <test-home>` without a
test system root when applying to prevent changes to the host during a test.
This also applies to Noctalia's automatic keyd setup. A dry-run preview is safe
without a test system root.

## Noctalia and shell preferences

Noctalia GUI overrides in `~/.local/state/noctalia/settings.toml` take precedence
over the deployed TOML. The installer preserves them. If you want to reset GUI
choices to the repo defaults, quit Noctalia and back up/move that state file
out of the state directory before restarting. For a custom `XDG_STATE_HOME`,
use its `noctalia/settings.toml` instead.

Legacy Noctalia `settings.json` and `plugins.json` are retained for reference
and excluded from deployment. The native snapshot enables screen-recorder and
bongocat plugins; install them through Noctalia's plugins UI if widgets are
missing. Plugin caches, clipboard history, notification logs and credentials
are not deployed.

The original Fish theme selection (`catppuccin-mocha`) and Hydro preferences
are retained. If you use Hydro, install it explicitly through Fisher; Fish
startup no longer downloads plugins. The theme must already be available to
Fish. No new color palette or terminal is introduced by this installer.

The snapshot keeps `us,ru,ua` keyboard layouts (Caps Lock cycles), idle timers
of 2 minutes to turn screens off, 4 to lock and 15 to lock/suspend, and the
existing Catppuccin desktop theme. Monitor overrides are disabled by default;
run `niri msg outputs` and edit `.config/niri/cfg/display.kdl` for your hardware.
The Noctalia config includes Bongocat's stable virtual keyboard. Lockscreen
positions can be adjusted through the UI.

After Noctalia GUI changes, export settings you want to retain:

```fish
noctalia config export merged > /tmp/noctalia-config.toml
noctalia config validate /tmp/noctalia-config.toml
```

Review personal paths and obsolete widgets, then copy the export into
`.config/noctalia/config.toml`. Theme templates can update app colors outside
this repo; copy generated settings you want to keep into the repo before
redeploying.

## Finish a fresh session setup

CachyOS usually configures these services already. Check them and enable the
ones you need:

```fish
sudo systemctl enable --now NetworkManager.service bluetooth.service
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
systemctl --user enable --now gnome-keyring-daemon.socket
systemctl --user enable --now polkit-kde.service
xdg-user-dirs-update
mkdir -p ~/Pictures/Screenshots
chsh -s /usr/bin/fish
```

Select **Niri** in your existing login manager, or use `niri-session` from a
TTY. Niri starts Noctalia automatically. Use one Polkit agent: the commands
above reproduce this machine's KDE agent service; disable it if you enable
Noctalia's agent instead.

For tmux plugins, install TPM once:

```fish
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
tmux
```

Press Ctrl+B, then Shift+I to install Catppuccin, resurrect, continuum, sensible,
CPU and battery plugins. Fish's Ctrl+R opens Atuin; `y` opens Yazi and changes
directory on exit. Niri's Mod is Super/Windows: Mod+Space opens the launcher,
Ctrl+Alt+T opens Alacritty, Mod+B/Z/E opens Brave Origin/Zed/Nautilus,
Mod+Alt+L locks and Mod+Shift+Q suspends. Mod+Shift+Escape shows all shortcuts.

## Installer checks

```fish
fish --no-config tests/test_setup.fish
```

These checks deploy into temporary homes, exercising optional images, repeated
deployment, backups and shared directory links. They also load the deployed
image settings through Noctalia with fresh state, decode both PNGs using its
theme tool, and validate the deployed Niri config. They do not install packages
or test a complete fresh CachyOS login; graphics hardware and future package
versions still need validation on the new machine. Select both `noctalia` in
the configs checklist and the wallpaper option to apply the wallpaper settings.
Selecting only the image copies it without changing the shell's configuration.

Push committed changes to GitHub before following the clone instructions on
a new machine, or copy the updated repository there directly. A clone from
GitHub includes only changes that have been pushed.
