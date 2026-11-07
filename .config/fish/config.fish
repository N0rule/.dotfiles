# ── Base ──────────────────────────────────────────────────────────────────────
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

status is-interactive; or return

# ── Environment ───────────────────────────────────────────────────────────────
set -gx EDITOR zeditor

# ── Integrations ──────────────────────────────────────────────────────────────
command -q atuin; and atuin init fish | source
if command -q zoxide
    zoxide init fish | source
    alias cd 'z'
end
command -q fzf; and fzf --fish | source

# ── Greeting ──────────────────────────────────────────────────────────────────
# Uncomment to silence the default CachyOS fastfetch greeting
# function fish_greeting
# end

# ── Theme ───────────────────────────────────────────────────────────────────
if test -f "$__fish_config_dir/themes/catppuccin-mocha.theme"
    fish_config theme choose catppuccin-mocha
end

set hydro_multiline true
set hydro_color_pwd blue
set hydro_color_prompt magenta
# ── Aliases ───────────────────────────────────────────────────────────────────
command -q bat; and alias cat 'bat'
alias c   'clear'
alias clr 'clear'
function paruupdate --wraps='paru -Syu' --description 'Update packages unattended after initial sudo authentication'
    sudo -v; or return $status
    command paru -Syu --sudoloop --noconfirm $argv
end

# ── Functions ─────────────────────────────────────────────────────────────────
# Remove orphan packages (safe: checks before running)
function parucleanup
    set -l orphans (paru -Qdtq)
    set -l result $status
    if test "$result" -gt 1
        return $result
    end
    if test (count $orphans) -gt 0
        paru -Rns $orphans
    else
        echo "No orphan packages found."
    end
end

# Yazi — change directory on exit
function y
    set -l tmp (mktemp -t "yazi-cwd.XXXXXX"); or return 1
    command yazi $argv --cwd-file="$tmp"
    set -l result $status
    set -l cwd
    if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
    return $result
end
