# Dotfiles audit — 2026-11-07

## Scope and outcome

Reviewed the installer, system helpers, tests, package manifests, application
configs, legacy snapshots, deployment paths, backups and documentation. Existing
uncommitted appearance, Fish and Niri customizations were preserved. This audit
validates the repository, not every possible fresh CachyOS installation.

## Fixed

- Niri referenced PiP helpers present on the machine but absent from Git. Added
  executable helpers, Python to the package list, portable XDG-aware bindings,
  Brave-only matching, checked IPC calls for snapping and event-stream tests.
- Fish optional integrations no longer fail when their packages are skipped.
  Missing local themes are skipped, `cd` remains usable without zoxide, and
  the Yazi wrapper handles temporary-file failure and returns Yazi's status.
- Fingerprint packages are no longer part of the default install selection.
  Explicit selection and automatic `--elitebook` dependencies remain available.
- System masks and system backups now share directory-symlink protections with
  system copies. Home backups reject symlinked backup ancestors before moving
  originals. Regression tests confirm outside directories remain untouched.
- Missing tmux plugin checkouts no longer cause unconditional startup errors.
- Tightened the wallpaper namespace regex and corrected the settings-window
  rule's misleading floating comment.
- Removed `pam_unix`'s `nullok` option from the optional greetd snapshot. An empty
  password must not authenticate a passwordless account through this shortcut;
  an empty greeter submission can still fall through to fingerprint auth.
- Removed documentation for the nonexistent SDDM option and documented Python,
  fingerprint package defaults, PiP and unattended-update behavior.

## Validation

- `fish --no-config setup.fish --check`: Niri, native Noctalia, Fish and keyd.
- `fish --no-config tests/test_setup.fish`: staged deployment, images decoded
  with Noctalia, repeatability, backups, directory links, optional packages,
  executable PiP deployment and system masks. No sudo or live service changes.
- `python3 tests/test_configs.py`: all tracked application TOML, legacy JSON,
  syntax-highlighting plist and mocked PiP IPC behavior.
- Fastfetch config executed successfully with the installed version.
- tmux config loaded in a separate disposable server, not the user's server.
- PiP action flags compared with the installed Niri CLI help.
- `git diff --check`.

Installed versions checked: Niri 26.04-1.1, Noctalia
5.4.1.r6286.gf90f230f8-1, Fish 4.9.3 and tmux 3.8.

## Remaining constraints and intentional choices

- The Niri blur configuration requires the CachyOS build; upstream Niri may
  reject it. Monitor configuration remains intentionally autodetected.
- A graphical login, lock/unlock, fingerprint enrollment, polkit authentication,
  device ACLs, multi-monitor PiP movement and suspend/resume need manual testing
  on the target hardware. PAM validation here is review, not a live login test.
- EliteBook PAM snapshots replace whole files and need comparison with the
  target distribution's auth stack. Keep an authenticated recovery terminal
  open when applying them. Fingerprint packages may require a sensor-specific
  fork; the installer cannot guarantee sensor compatibility.
- `paruupdate --noconfirm` is an existing preference, not a safe default for
  reviewing AUR updates. Plain `paru -Syu` remains the interactive alternative.
- Noctalia GUI state overrides deployed TOML. Plugin preferences do not install
  plugins; install them in Noctalia. TPM and Hydro also need explicit setup.
- tmux plugin and reload paths still use the documented `~/.config/tmux`
  location. Custom XDG users need to adapt those plugin paths.
- Legacy Noctalia JSON and `.config/niri.zip` remain historical references and
  are not deployed by the installer. They contain old paths/settings and must
  not be used as current configuration.
- No obvious committed credentials were found during content review. Personal
  paths in historical JSON remain; this was not a forensic Git-history scan.
- Package availability and future rolling-release compatibility are not
  guaranteed. No host upgrades, package installation or service restarts were
  performed as part of this audit.
