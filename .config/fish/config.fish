# ── Base ──────────────────────────────────────────────────────────────────────
source /usr/share/cachyos-fish-config/cachyos-config.fish

# ── Environment ───────────────────────────────────────────────────────────────
set -gx EDITOR nvim

# ── Integrations ──────────────────────────────────────────────────────────────
atuin init fish | source
zoxide init fish | source
fzf --fish | source

# ── Greeting ──────────────────────────────────────────────────────────────────
# Uncomment to silence the default CachyOS fastfetch greeting
# function fish_greeting
# end

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
