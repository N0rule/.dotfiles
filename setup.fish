#!/usr/bin/env -S fish --no-config
# CachyOS + Niri + native Noctalia. No Python or UI dependency.
set -g setup_root (path dirname (status filename) | path resolve)
set -g setup_home $HOME
set -g setup_install 0
set -g setup_apply 0
set -g setup_dry 0
set -g setup_wallpaper 0
set -g setup_avatar 0
set -g setup_keyd 0
set -g setup_elitebook 0
set -g setup_system_root /
source "$setup_root/scripts/keyd.fish"
set -g setup_configs niri noctalia fish alacritty tmux atuin btop fastfetch yazi
set -g setup_repo
set -g setup_aur

function fail
    printf 'Error: %s\n' "$argv" >&2
    return 1
end

function read_packages --argument-names file
    while read -l line
        set -l value (string trim -- (string replace -r '#.*$' '' -- "$line"))
        if test -n "$value"
            printf '%s\n' "$value"
        end
    end < "$file"
end

function usage
    printf '%s\n' \
        'Usage: fish setup.fish                    Open the terminal checklist' \
        '       fish setup.fish --dry-run          Preview all configs, without images' \
        '       fish setup.fish --install          Install selected packages' \
        '       fish setup.fish --apply            Deploy selected configs' \
        '' \
        'Options:' \
        '  --packages niri,noctalia-git,...  Package selection (default: all)' \
        '  --configs niri,noctalia,...       Config selection (default: all)' \
        '  --wallpaper                      Include the wallpaper and its settings' \
        '  --avatar                         Include the profile image and its settings' \
        '  --keyd                           Configure/start keyd for Bongocat (uses sudo)' \
        '  --elitebook                      Enable HP button mappings (implies --keyd)' \
        '  --system-root DIR                Stage system files without touching services' \
        '  --home DIR                       Deploy into an existing test home' \
        '  --dry-run                        Print the plan without making changes' \
        '  --check                          Validate repo configs; write nothing' \
        '  --list                           List available packages and configs' \
        '  --help                           Show this help' \
        '' \
        'Use none for an empty --packages or --configs selection.' \
        'Package installation affects the system even when --home is used.'
end

# Built-in numbered checklist. Output goes to stderr, selected tags to stdout.
function checklist --argument-names title initial
    set -l items $argv[3..]
    set -l selected
    if test "$initial" = all
        set selected $items
    else if contains -- "$initial" $items
        set selected "$initial"
    end
    while true
        printf '\n%s\n' "$title" >&2
        for i in (seq (count $items))
            set -l mark ' '
            contains -- "$items[$i]" $selected; and set mark x
            printf '  %2d [%s] %s\n' $i "$mark" "$items[$i]" >&2
        end
        printf 'Numbers toggle items (e.g. 2 5). a=all, n=none, Enter=done, q=cancel\n> ' >&2
        read -l -P '' answer; or return 1
        switch (string trim -- "$answer")
            case ''
                if test (count $selected) -gt 0
                    printf '%s\n' $selected
                end
                return 0
            case q Q
                return 1
            case a A
                set selected $items
            case n N
                set selected
            case '*'
                for token in (string split -n ' ' -- (string trim -- "$answer"))
                    if not string match -rq '^[0-9]+$' -- "$token"
                        printf 'Unknown selection: %s\n' "$token" >&2
                        continue
                    end
                    if test "$token" -lt 1; or test "$token" -gt (count $items)
                        printf 'Number out of range: %s\n' "$token" >&2
                        continue
                    end
                    set -l item "$items[$token]"
                    if contains -- "$item" $selected
                        set -e selected[(contains -i -- "$item" $selected)]
                    else
                        set -a selected "$item"
                    end
                end
        end
    end
end

function print_command
    printf '+ %s\n' (string join ' ' -- (string escape -- $argv))
end

function run_command
    print_command $argv
    if test "$setup_dry" = 0
        command $argv; or return 1
    end
end

function render_noctalia
    # Remove image settings when the corresponding optional asset is skipped.
    awk -v wallpaper="$setup_wallpaper" -v avatar="$setup_avatar" -v keyd="$setup_keyd" '
        /^\[/ { skip = (!wallpaper && $0 ~ /^\[\[?wallpaper(\.|\])/); }
        skip { next; }
        !avatar && /^[[:space:]]*(avatar_path|custom_image)[[:space:]]*=/ { next; }
        !keyd && /keyd-virtual-keyboard/ { next; }
        { print; }
    ' "$setup_root/.config/noctalia/config.toml"
end

function save_target --argument-names target
    set -l relative (string sub -s (math (string length -- "$setup_home") + 2) -- "$target")
    set -l saved "$setup_backup/$relative"
    if test -L "$target"
        set saved "$saved.symlink"
    end
    printf 'Backup %s -> %s\n' "$target" "$saved"
    if test "$setup_dry" = 0
        mkdir -p -- (path dirname "$saved"); or return 1
        if test -L "$target"
            # Absolute backup links preserve the meaning of relative Stow links.
            set -l resolved (readlink -m -- "$target"); or return 1
            ln -s -- "$resolved" "$saved"; or return 1
            rm -- "$target"; or return 1
        else
            mv -- "$target" "$saved"; or return 1
        end
    end
    set -g setup_saved "$saved"
end

function copy_file --argument-names source target rendered
    if test -f "$target"
        if test "$rendered" = native
            set -l existing (string collect -N < "$target")
            if test "$existing" = "$setup_native"
                printf 'Unchanged %s\n' "$target"
                return 0
            end
        else if cmp -s -- "$source" "$target"
            printf 'Unchanged %s\n' "$target"
            return 0
        end
    end
    # Walk parents from home downward; detach directory links before writing.
    set -l parents
    set -l parent (path dirname "$target")
    while test "$parent" != "$setup_home"
        set -p parents "$parent"
        set parent (path dirname "$parent")
        if test "$parent" = /
            fail "Target is outside the deployment home: $target"
            return 1
        end
    end
    for parent in $parents
        if test -L "$parent"; or begin; test -e "$parent"; and not test -d "$parent"; end
            save_target "$parent"; or return 1
            if test "$setup_dry" = 0
                if test -d "$setup_saved"
                    mkdir -p -- "$parent"; or return 1
                    cp -a -- "$setup_saved/." "$parent/"; or return 1
                else
                    mkdir -p -- "$parent"; or return 1
                end
            end
        end
    end
    if test -e "$target"; or test -L "$target"
        save_target "$target"; or return 1
    end
    printf 'Copy %s -> %s\n' "$source" "$target"
    if test "$setup_dry" = 0
        mkdir -p -- (path dirname "$target"); or return 1
        if test "$rendered" = native
            printf '%s' "$setup_native" > "$target"; or return 1
        else
            cp -p -- "$source" "$target"; or return 1
        end
    end
end

function deploy
    set -g setup_backup "$setup_home/.local/state/dotfiles-backups/"(date +%Y%m%d-%H%M%S-%N)
    set -g setup_native (render_noctalia | string collect -N)
    for config in $setup_selected_configs
        if test "$config" = noctalia
            copy_file "$setup_root/.config/noctalia/config.toml" "$setup_config_home/noctalia/config.toml" native; or return 1
            continue
        end
        # Do not deploy plugin checkout/cache directories.
        set -l files (find "$setup_root/.config/$config" -type d -name plugins -prune -o -type f -print0 | sort -z | string split0)
        for source in $files
            set -l relative (string sub -s (math (string length -- "$setup_root/.config/") + 1) -- "$source")
            copy_file "$source" "$setup_config_home/$relative" plain; or return 1
        end
    end
    if test "$setup_wallpaper" = 1
        copy_file "$setup_root/assets/Nanachi-Splash.png" "$setup_home/Pictures/Dotfiles/Nanachi-Splash.png" plain; or return 1
    end
    if test "$setup_avatar" = 1
        copy_file "$setup_root/assets/ProfileIcon.png" "$setup_home/Pictures/Dotfiles/ProfileIcon.png" plain; or return 1
    end
    if test -d "$setup_backup"
        printf 'Backups: %s\n' "$setup_backup"
    end
end

function validate_configs
    for binary in niri noctalia fish
        command -q "$binary"; or begin; fail "$binary is missing; install it before --check"; return 1; end
    end
    niri validate -c "$setup_root/.config/niri/config.kdl"; or return 1
    noctalia config validate "$setup_root/.config/noctalia/config.toml"; or return 1
    fish --no-config -n "$setup_root/.config/fish/config.fish"; or return 1
    fish --no-config -n "$setup_root/setup.fish"; or return 1
    fish --no-config -n "$setup_root/scripts/keyd.fish"; or return 1
    if command -q keyd
        keyd check "$setup_root/system/keyd/default.conf" "$setup_root/system/keyd/elitebook.conf"; or return 1
    end
end

function main
    set -l interactive 0
    if test (count $argv) = 0
        set interactive 1
    end
    argparse h/help install apply dry-run check list wallpaper avatar keyd elitebook 'system-root=' 'home=' 'packages=' 'configs=' -- $argv; or return 2
    if test (count $argv) -gt 0
        fail "Unexpected argument: $argv"
        return 2
    end
    if set -q _flag_help
        usage
        return 0
    end
    set -g setup_repo (read_packages "$setup_root/packages/repo.txt")
    set -g setup_aur (read_packages "$setup_root/packages/aur.txt")
    set -g setup_selected_packages $setup_repo $setup_aur
    set -g setup_selected_configs $setup_configs
    if set -q _flag_list
        printf 'Repository packages:\n%s\n\nAUR packages:\n%s\n\nConfigs:\n%s\n' \
            (string join '\n' $setup_repo) (string join '\n' $setup_aur) (string join '\n' $setup_configs) | string replace -a '\n' \n
        return 0
    end
    if set -q _flag_check
        validate_configs; or return 1
        if not set -q _flag_apply; and not set -q _flag_install
            return 0
        end
    end
    set -q _flag_install; and set -g setup_install 1
    set -q _flag_apply; and set -g setup_apply 1
    set -q _flag_dry_run; and set -g setup_dry 1
    set -q _flag_wallpaper; and set -g setup_wallpaper 1
    set -q _flag_avatar; and set -g setup_avatar 1
    set -q _flag_keyd; and set -g setup_keyd 1
    if set -q _flag_elitebook
        set -g setup_elitebook 1
        set -g setup_keyd 1
    end
    if set -q _flag_system_root
        test -d "$_flag_system_root"; or begin; fail 'System staging directory must already exist'; return 1; end
        set -g setup_system_root (realpath -e -- "$_flag_system_root"); or return 1
    end
    if set -q _flag_home
        set -g setup_home "$_flag_home"
    end
    if set -q _flag_packages
        set -g setup_selected_packages
        if test "$_flag_packages" != none
            set -g setup_selected_packages (string split ',' -- "$_flag_packages")
        end
    end
    if set -q _flag_configs
        set -g setup_selected_configs
        if test "$_flag_configs" != none
            set -g setup_selected_configs (string split ',' -- "$_flag_configs")
        end
    end
    for package in $setup_selected_packages
        contains -- "$package" $setup_repo $setup_aur; or begin; fail "Unknown package: $package"; return 2; end
    end
    for config in $setup_selected_configs
        contains -- "$config" $setup_configs; or begin; fail "Unknown config: $config"; return 2; end
    end
    if test "$interactive" = 1
        if not isatty stdin
            fail 'The checklist needs a terminal. Use --help for noninteractive options.'
            return 2
        end
        printf '\nCachyOS + Niri + native Noctalia setup\n\n1. Packages and configs\n2. Packages only\n3. Configs only\nq. Cancel\nChoose [1]: '
        read -l -P '' mode; or return 1
        switch "$mode"
            case '' 1
                set -g setup_install 1
                set -g setup_apply 1
            case 2
                set -g setup_install 1
            case 3
                set -g setup_apply 1
            case q Q
                return 0
            case '*'
                fail 'Choose 1, 2, 3 or q'
                return 2
        end
        if test "$setup_install" = 1
            set -g setup_selected_packages (checklist 'Packages (repo + AUR; selected by default)' all $setup_repo $setup_aur)
            or return 0
        end
        if test "$setup_apply" = 1
            set -g setup_selected_configs (checklist 'Configurations (independent of package selection)' all $setup_configs)
            or return 0
            set -l images (checklist 'Optional images (both off by default)' none wallpaper profile-image)
            or return 0
            contains -- wallpaper $images; and set -g setup_wallpaper 1
            contains -- profile-image $images; and set -g setup_avatar 1
            set -l keyboard (checklist 'System keyboard setup (opt-in; EliteBook mappings off by default)' none keyd-bongocat elitebook-buttons)
            or return 0
            contains -- keyd-bongocat $keyboard; and set -g setup_keyd 1
            if contains -- elitebook-buttons $keyboard
                set -g setup_elitebook 1
                set -g setup_keyd 1
            end
        end
    else if test "$setup_install" = 0; and test "$setup_apply" = 0
        if test "$setup_dry" = 1
            set -g setup_apply 1
        else
            usage
            return 2
        end
    end
    test -d "$setup_home"; or begin; fail "Home must already exist: $setup_home"; return 1; end
    set -g setup_home (realpath -e -- "$setup_home"); or return 1
    if test "$setup_keyd" = 1; and test "$setup_apply" != 1
        fail 'Keyd setup requires --apply (or --apply --dry-run)'
        return 2
    end
    if test "$setup_keyd" = 1; and test "$setup_system_root" = /; and test "$setup_home" != (realpath -e -- "$HOME")
        fail 'Use --system-root for keyd tests with --home; otherwise keyd would change the host'
        return 2
    end
    set -g setup_config_home "$setup_home/.config"
    if test "$setup_home" = (realpath -e -- "$HOME"); and set -q XDG_CONFIG_HOME; and test -n "$XDG_CONFIG_HOME"
        set -g setup_config_home (realpath -ms -- "$XDG_CONFIG_HOME")
    end
    if not string match -q -- "$setup_home/*" "$setup_config_home"
        fail 'XDG_CONFIG_HOME must be inside the destination home'
        return 1
    end
    if contains -- noctalia $setup_selected_configs; and test "$setup_apply" = 1; and set -q NOCTALIA_CONFIG_HOME
        fail 'Unset NOCTALIA_CONFIG_HOME before deploying Noctalia'
        return 1
    end
    set -l package_summary "(none selected)"
    set -l config_summary "(none selected)"
    if test "$setup_install" = 1; and test (count $setup_selected_packages) -gt 0
        set package_summary (string join ', ' -- $setup_selected_packages)
    end
    if test "$setup_apply" = 1; and test (count $setup_selected_configs) -gt 0
        set config_summary (string join ', ' -- $setup_selected_configs)
    end
    printf '\nPlan\nPackages: %s\nConfigs: %s\nWallpaper: %s   Profile image: %s\nDestination: %s\n' \
        "$package_summary" "$config_summary" \
        "$setup_wallpaper" "$setup_avatar" "$setup_home"
    printf 'Package installation: %s   Config deployment: %s\n' "$setup_install" "$setup_apply"
    printf 'Keyd/Bongocat system setup: %s   HP EliteBook remaps: %s\n' "$setup_keyd" "$setup_elitebook"
    if test "$setup_keyd" = 1
        printf 'System destination: %s (existing keyd default.conf will be backed up/replaced if different)\n' "$setup_system_root"
    end
    printf 'Configs can reference apps/plugins you skip installing. Noctalia GUI overrides remain in effect.\n'
    if test "$setup_apply" = 1; and begin; test "$setup_wallpaper" = 1; or test "$setup_avatar" = 1; end
        if not contains -- noctalia $setup_selected_configs
            printf 'Images will be copied only. Select the noctalia config to apply their shell settings.\n'
        end
    end
    if test "$interactive" = 1
        printf '\n1. Apply (default)\n2. Test apply (preview only)\n3. Cancel\nChoose [1]: '
        read -l -P '' decision; or return 1
        switch "$decision"
            case '' 1
                set -g setup_dry 0
            case 2
                set -g setup_dry 1
            case 3
                return 0
            case '*'
                fail 'Choose 1, 2 or 3'
                return 2
        end
    end
    if test "$setup_dry" = 0; and test (id -u) = 0
        fail 'Run as your normal user, without sudo. Only pacman needs sudo.'
        return 1
    end
    if test "$setup_install" = 1; and test (count $setup_selected_packages) -gt 0
        set -l selected_repo
        set -l selected_aur
        for package in $setup_selected_packages
            if contains -- "$package" $setup_repo
                set -a selected_repo "$package"
            else
                set -a selected_aur "$package"
            end
        end
        if test "$setup_dry" = 0
            string match -rq '^ID="?cachyos"?$' < /etc/os-release; or begin; fail 'Automatic installation targets CachyOS'; return 1; end
            if test (count $selected_aur) -gt 0; and not command -q paru; and not contains -- paru $selected_repo
                fail 'AUR selections need paru; select paru too, or install it first'
                return 1
            end
        end
        run_command sudo pacman -Syu --needed $selected_repo; or return 1
        if test (count $selected_aur) -gt 0
            run_command paru -S --needed $selected_aur; or return 1
        end
    end
    if test "$setup_apply" = 1
        if test "$setup_keyd" = 1
            setup_keyd_system; or return 1
        end
        deploy; or return 1
    end
    if test "$setup_dry" = 1
        printf '\nPreview complete. No files or packages changed.\n'
    else
        printf '\nSetup complete. See README.md for login, services and optional plugins.\n'
    end
end

main $argv
