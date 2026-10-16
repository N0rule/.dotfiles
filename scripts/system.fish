# System setup helpers, sourced by setup.fish. Staging never uses sudo/services.
function system_begin
    # Initialise the sudo prefix and one shared backup directory per run.
    if set -q setup_system_ready
        return 0
    end
    set -g setup_system_prefix
    if test "$setup_system_root" = /
        set -g setup_system_prefix sudo
    end
    set -g setup_system_backup (path normalize "$setup_system_root/var/backups/dotfiles/"(date +%Y%m%d-%H%M%S-%N))
    set -g setup_system_ready 1
end

function system_copy --argument-names source relative
    set -l target (path normalize "$setup_system_root/$relative")
    set -l parent (path dirname "$target")
    set -l ancestor "$parent"
    while test "$ancestor" != "$setup_system_root"; and test "$ancestor" != /
        if test -L "$ancestor"
            fail "Refusing to write system files through directory link: $ancestor"
            return 1
        end
        set ancestor (path dirname "$ancestor")
    end
    if test -f "$target"; and cmp -s -- "$source" "$target"
        printf 'Unchanged %s\n' "$target"
        return 0
    end
    if test -e "$target"; or test -L "$target"
        set -l saved "$setup_system_backup/$relative"
        run_command $setup_system_prefix mkdir -p -- (path dirname "$saved"); or return 1
        if test -L "$target"
            set saved "$saved.symlink"
            run_command $setup_system_prefix ln -s -- (readlink -m -- "$target") "$saved"; or return 1
            run_command $setup_system_prefix unlink -- "$target"; or return 1
        else
            run_command $setup_system_prefix mv -- "$target" "$saved"; or return 1
        end
        printf 'System backup: %s\n' "$saved"
    end
    run_command $setup_system_prefix install -D -m 0644 -- "$source" "$target"; or return 1
end

function system_mask --argument-names relative
    # Replace a unit file with a symlink to /dev/null (a systemd mask).
    set -l target (path normalize "$setup_system_root/$relative")
    if test -L "$target"; and test (readlink -- "$target") = /dev/null
        printf 'Unchanged %s\n' "$target"
        return 0
    end
    if test -e "$target"; or test -L "$target"
        set -l saved "$setup_system_backup/$relative"
        run_command $setup_system_prefix mkdir -p -- (path dirname "$saved"); or return 1
        if test -L "$target"
            set saved "$saved.symlink"
            run_command $setup_system_prefix ln -s -- (readlink -m -- "$target") "$saved"; or return 1
            run_command $setup_system_prefix unlink -- "$target"; or return 1
        else
            run_command $setup_system_prefix mv -- "$target" "$saved"; or return 1
        end
        printf 'System backup: %s\n' "$saved"
    end
    run_command $setup_system_prefix mkdir -p -- (path dirname "$target"); or return 1
    run_command $setup_system_prefix ln -sf /dev/null "$target"; or return 1
end

function setup_keyd_system
    set -l profile default.conf
    test "$setup_elitebook" = 1; and set profile elitebook.conf
    if command -q keyd
        keyd check "$setup_root/system/keyd/$profile"; or return 1
    else if test "$setup_dry" = 0
        fail 'keyd is missing; select the keyd package or install it first'
        return 1
    end
    system_begin
    if test "$setup_system_root" = /; and test "$setup_dry" = 0; and not command -q evtest
        fail 'evtest is missing; select the evtest package or install it first'
        return 1
    end
    system_copy "$setup_root/system/keyd/$profile" etc/keyd/default.conf; or return 1
    system_copy "$setup_root/system/udev/70-keyd-bongocat.rules" etc/udev/rules.d/70-keyd-bongocat.rules; or return 1
    if test "$setup_system_root" != /
        printf 'Staged keyd config and udev rule only; host services and devices unchanged.\n'
        return 0
    end
    # Validate the complete installed config set before restarting keyd.
    run_command sudo keyd check; or return 1
    run_command sudo udevadm control --reload-rules; or return 1
    run_command sudo systemctl enable --now keyd.service; or return 1
    run_command sudo systemctl restart keyd.service; or return 1
    run_command sudo udevadm trigger --subsystem-match=input; or return 1
    run_command sudo udevadm settle; or return 1
    if test "$setup_dry" = 0
        if not test -r /dev/input/by-id/keyd-virtual-keyboard
            printf 'Virtual keyboard not readable yet. Log out/in, then check the path in Bongocat settings.\n'
        end
    end
end

function setup_fingerprint_system
    # Fingerprint-first login for this HP EliteBook: pam_fprintd ahead of the
    # password stack for sudo and polkit, with the stock fprintd masked so
    # open-fprintd owns net.reactivated.Fprint. greetd keeps the password step
    # first and adds keyring unlock plus a fprintd fallback after an empty
    # submission ([auth].allow_empty_password in greeter.toml).
    system_begin
    for file in sudo polkit-1 greetd
        system_copy "$setup_root/system/pam/$file" "etc/pam.d/$file"; or return 1
    end
    system_mask etc/systemd/system/fprintd.service; or return 1
    if test "$setup_system_root" != /
        printf 'Staged PAM rules and the fprintd mask only; host services unchanged.\n'
        return 0
    end
    run_command sudo systemctl daemon-reload; or return 1
    run_command sudo systemctl enable --now open-fprintd.service python3-validity.service; or return 1
    run_command sudo systemctl restart python3-validity.service; or return 1
    if test "$setup_dry" = 0; and not command -q fprintd-list
        printf 'fprintd-list missing; install fprintd-clients-git, then enroll with fprintd-enroll.\n'
    end
end
