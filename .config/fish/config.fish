# ── Base ──────────────────────────────────────────────────────────────────────
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

status is-interactive; or return

# ── Environment ───────────────────────────────────────────────────────────────
set -gx EDITOR zeditor

# ── Integrations ──────────────────────────────────────────────────────────────
atuin init fish | source
zoxide init fish | source
fzf --fish | source

# ── Greeting ──────────────────────────────────────────────────────────────────
# Uncomment to silence the default CachyOS fastfetch greeting
# function fish_greeting
# end

# ── Theme ───────────────────────────────────────────────────────────────────
fish_config theme choose catppuccin-mocha

set hydro_multiline true
set hydro_color_pwd blue
set hydro_color_prompt magenta
# ── Aliases ───────────────────────────────────────────────────────────────────
alias cat 'bat'
alias c   'clear'
alias clr 'clear'
alias cd  'z'
alias paruupdate 'paru -Syu'

# ── Functions ─────────────────────────────────────────────────────────────────
# Remove orphan packages (safe: checks before running)
function parucleanup
    set orphans (paru -Qdtq)
    if test -n "$orphans"
        paru -Rns $orphans
    else
        echo "No orphan packages found."
    end
end

# Yazi — change directory on exit
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
