#!/usr/bin/env fish
set -g root (path dirname (path dirname (status filename)) | path resolve)
set -g sandbox (mktemp -d -t dotfiles-tests.XXXXXX); or exit 1
function cleanup --on-event fish_exit
    rm -rf -- "$sandbox"
end
function expect
    if not test $argv
        printf 'FAIL: test %s\n' (string join ' ' -- $argv) >&2
        exit 1
    end
end
function invoke
    # Check both status and runtime diagnostics.
    # Noctalia now includes system setup by default. All test deployments use
    # a dedicated system root so they never invoke sudo or touch host services.
    if not contains -- --system-root $argv
        set -l home_index (contains -i -- --home $argv)
        if test -n "$home_index"
            set -l next (math "$home_index + 1")
            set -l staging "$argv[$next]-system"
            mkdir -p -- "$staging"; or exit 1
            set -a argv --system-root "$staging"
        end
    end
    fish --no-config "$root/setup.fish" $argv > "$sandbox/output" 2>&1
    set -l result $status
    if string match -rq "Unknown command|^fish:|^Error:" < "$sandbox/output"
        cat "$sandbox/output" >&2
        exit 1
    end
    if test "$result" -ne 0
        cat "$sandbox/output" >&2
        exit 1
    end
end

# Plain preview leaves an empty destination untouched.
mkdir "$sandbox/preview"
invoke --dry-run --home "$sandbox/preview"
expect (count (find "$sandbox/preview" -mindepth 1 -print)) -eq 0
printf 'PASS: dry run writes nothing\n'

# Install preview cannot execute package commands.
invoke --install --apply --dry-run --packages niri,noctalia-git --configs noctalia --home "$sandbox/preview"
expect (count (find "$sandbox/preview" -mindepth 1 -print)) -eq 0
if not string match -q '*+ sudo pacman -Syu --needed niri*' (string collect < "$sandbox/output")
    printf 'FAIL: package selection missing from plan\n' >&2
    exit 1
end
printf 'PASS: package selection preview\n'
invoke --install --dry-run --packages noctalia-git --configs none --home "$sandbox/preview"
if not string match -q '*+ sudo pacman -Syu --needed keyd evtest*' (string collect < "$sandbox/output")
    printf 'FAIL: Noctalia package selection omitted Bongocat dependencies\n' >&2
    exit 1
end
printf 'PASS: Noctalia package installation includes keyd and evtest\n'

# Default deployment omits both asset paths and files.
mkdir "$sandbox/plain"
invoke --apply --configs noctalia --home "$sandbox/plain"
set -l plain "$sandbox/plain/.config/noctalia/config.toml"
expect -f "$plain"
if string match -rq '^\[\[?wallpaper[.\]]|^avatar_path =|^custom_image =' < "$plain"
    printf 'FAIL: skipped images still referenced\n' >&2
    exit 1
end
expect ! -e "$sandbox/plain/Pictures"
noctalia config validate "$plain"; or exit 1
invoke --apply --configs noctalia --home "$sandbox/plain"
expect ! -e "$sandbox/plain/.local/state/dotfiles-backups"
printf 'PASS: no-image deployment and idempotence\n'
if not string match -q '*keyd-virtual-keyboard*' (string collect < "$plain")
    printf 'FAIL: default Noctalia deployment omitted Bongocat keyboard input\n' >&2
    exit 1
end
expect -f "$sandbox/plain-system/etc/keyd/default.conf"
cmp -s "$root/system/keyd/default.conf" "$sandbox/plain-system/etc/keyd/default.conf"; or exit 1
printf 'PASS: Noctalia automatically includes generic keyd/Bongocat setup\n'

# Each asset can be selected separately.
for choice in wallpaper avatar
    mkdir "$sandbox/$choice"
    invoke --apply --configs noctalia --$choice --home "$sandbox/$choice"
    set -l image ProfileIcon.png
    set -l skipped Nanachi-Splash.png
    if test "$choice" = wallpaper
        set image Nanachi-Splash.png
        set skipped ProfileIcon.png
    end
    expect -f "$sandbox/$choice/Pictures/Dotfiles/$image"
    expect ! -e "$sandbox/$choice/Pictures/Dotfiles/$skipped"
    cmp -s "$root/assets/$image" "$sandbox/$choice/Pictures/Dotfiles/$image"; or exit 1
    noctalia config validate "$sandbox/$choice/.config/noctalia/config.toml"; or exit 1
    # Load through Noctalia's actual config stack, with fresh state and no
    # existing GUI settings. NOCTALIA_*_HOME are base dirs, not /noctalia dirs.
    env NOCTALIA_CONFIG_HOME="$sandbox/$choice/.config" \
        NOCTALIA_STATE_HOME="$sandbox/$choice/state" \
        NOCTALIA_DATA_HOME="$sandbox/$choice/share" \
        noctalia config export merged > "$sandbox/$choice/effective.toml"; or exit 1
    if not string match -q "*~/Pictures/Dotfiles/$image*" (string collect < "$sandbox/$choice/effective.toml")
        printf 'FAIL: Noctalia did not load selected image settings\n' >&2
        exit 1
    end
    if string match -q "*~/Pictures/Dotfiles/$skipped*" (string collect < "$sandbox/$choice/effective.toml")
        printf 'FAIL: Noctalia loaded settings for a skipped image\n' >&2
        exit 1
    end
    # Exercise Noctalia's PNG decoder; file existence alone is insufficient.
    env NOCTALIA_CONFIG_HOME="$sandbox/$choice/.config" \
        NOCTALIA_STATE_HOME="$sandbox/$choice/state" \
        NOCTALIA_DATA_HOME="$sandbox/$choice/share" \
        noctalia theme "$sandbox/$choice/Pictures/Dotfiles/$image" --dark \
        -o "$sandbox/$choice/palette.json"; or exit 1
    expect -s "$sandbox/$choice/palette.json"
end
printf 'PASS: independent images, fresh Noctalia config loading and PNG decoding\n'

# Existing files are backed up; unrelated files remain.
mkdir -p "$sandbox/conflict/.config/alacritty"
printf old > "$sandbox/conflict/.config/alacritty/alacritty.toml"
printf keep > "$sandbox/conflict/.config/alacritty/unrelated"
invoke --apply --configs alacritty --home "$sandbox/conflict"
expect ! -e "$sandbox/conflict-system/etc/keyd/default.conf"
set -l backup (find "$sandbox/conflict/.local/state/dotfiles-backups" -mindepth 1 -maxdepth 1 -type d)
expect (cat "$backup/.config/alacritty/alacritty.toml") = old
expect (cat "$sandbox/conflict/.config/alacritty/unrelated") = keep
printf 'PASS: conflicting-file backup\n'

# Relative directory links are detached without changing the shared data.
mkdir -p "$sandbox/shared" "$sandbox/links/.config"
printf old > "$sandbox/shared/alacritty.toml"
printf keep > "$sandbox/shared/unrelated"
set -l shared_inode (stat -c %i "$sandbox/shared/alacritty.toml")
ln -s ../../shared "$sandbox/links/.config/alacritty"
invoke --apply --configs alacritty --home "$sandbox/links"
expect ! -L "$sandbox/links/.config/alacritty"
expect (cat "$sandbox/shared/alacritty.toml") = old
expect (stat -c %i "$sandbox/shared/alacritty.toml") = "$shared_inode"
expect (cat "$sandbox/links/.config/alacritty/unrelated") = keep
set backup (find "$sandbox/links/.local/state/dotfiles-backups" -mindepth 1 -maxdepth 1 -type d)
expect -L "$backup/.config/alacritty.symlink"
expect (readlink -f "$backup/.config/alacritty.symlink") = "$sandbox/shared"
printf 'PASS: shared directory-link preservation\n'

# Full deployment with both images is repeatable.
mkdir "$sandbox/full"
invoke --apply --wallpaper --avatar --home "$sandbox/full"
invoke --apply --wallpaper --avatar --home "$sandbox/full"
expect ! -e "$sandbox/full/.local/state/dotfiles-backups"
expect ! -e "$sandbox/full/.config/kitty"
expect ! -e "$sandbox/full/.config/noctalia/settings.json"
niri validate -c "$sandbox/full/.config/niri/config.kdl"; or exit 1
fish --no-config -n "$sandbox/full/.config/fish/config.fish"; or exit 1
printf 'PASS: full deployment, repeat run, no Kitty/legacy JSON\n'
expect -f "$sandbox/full/.config/yazi/flavors/noctalia.yazi/tmtheme.xml"
cmp -s "$root/.config/yazi/flavors/noctalia.yazi/tmtheme.xml" \
    "$sandbox/full/.config/yazi/flavors/noctalia.yazi/tmtheme.xml"; or exit 1
printf 'PASS: Yazi syntax-highlighting theme deployment\n'

# Noctalia automatically stages system configuration, without a --keyd flag.
mkdir "$sandbox/keyd-home" "$sandbox/keyd-system"
invoke --apply --configs noctalia --home "$sandbox/keyd-home" --system-root "$sandbox/keyd-system"
set -l keyd_config "$sandbox/keyd-system/etc/keyd/default.conf"
expect -f "$keyd_config"
cmp -s "$root/system/keyd/default.conf" "$keyd_config"; or exit 1
if string match -q '*macro(*' (string collect < "$keyd_config")
    printf 'FAIL: EliteBook mappings enabled in generic profile\n' >&2
    exit 1
end
if not string match -q '*keyd-virtual-keyboard*' (string collect < "$sandbox/keyd-home/.config/noctalia/config.toml")
    printf 'FAIL: missing Bongocat device for selected keyd setup\n' >&2
    exit 1
end
expect -f "$sandbox/keyd-system/etc/udev/rules.d/70-keyd-bongocat.rules"
invoke --apply --configs noctalia --home "$sandbox/keyd-home" --system-root "$sandbox/keyd-system"
expect ! -e "$sandbox/keyd-system/var/backups/dotfiles"
printf 'PASS: generic keyd staging, Bongocat device and repeated deployment\n'

# The HP mappings require an explicit flag and replace the generic profile.
invoke --apply --elitebook --configs noctalia --home "$sandbox/keyd-home" --system-root "$sandbox/keyd-system"
cmp -s "$root/system/keyd/elitebook.conf" "$keyd_config"; or exit 1
set -l system_backup (find "$sandbox/keyd-system/var/backups/dotfiles" -mindepth 1 -maxdepth 1 -type d)
cmp -s "$root/system/keyd/default.conf" "$system_backup/etc/keyd/default.conf"; or exit 1
printf 'PASS: EliteBook opt-in and system backup\n'

# Previewing system setup creates no files and executes no services.
mkdir "$sandbox/keyd-preview-home" "$sandbox/keyd-preview-system"
invoke --apply --dry-run --configs noctalia --home "$sandbox/keyd-preview-home" --system-root "$sandbox/keyd-preview-system"
expect (count (find "$sandbox/keyd-preview-home" -mindepth 1 -print)) -eq 0
expect (count (find "$sandbox/keyd-preview-system" -mindepth 1 -print)) -eq 0
printf 'PASS: keyd preview writes nothing\n'
printf '\nAll installer checks passed.\n'
