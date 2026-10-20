#!/usr/bin/env bash

set -u

section() {
    printf '\n===== %s =====\n' "$1"
}

run_check() {
    local label="$1"
    shift
    printf '\n--- %s ---\n' "$label"
    "$@" 2>&1 || echo "[WARN] Check failed: $label"
}

if [[ "${EUID}" -eq 0 ]]; then
    SUDO=()
elif command -v sudo >/dev/null 2>&1; then
    SUDO=(sudo)
else
    echo "ERROR: sudo is required for some checks."
    exit 1
fi

section "SYSTEM"
run_check "OS" bash -c 'cat /etc/os-release | grep -E "^(PRETTY_NAME|VERSION_ID)="'
run_check "Kernel" uname -r

section "SSH HARDENING"
if command -v sshd >/dev/null 2>&1; then
    "${SUDO[@]}" sshd -T 2>/dev/null |
        grep -E '^(permitrootlogin|passwordauthentication|pubkeyauthentication|kbdinteractiveauthentication|maxauthtries) ' ||
        echo "[WARN] Could not read effective SSH configuration."
else
    echo "[SKIP] sshd is not installed."
fi

section "FIREWALL"
if command -v ufw >/dev/null 2>&1; then
    "${SUDO[@]}" ufw status verbose
else
    echo "[WARN] UFW is not installed."
fi

section "FAIL2BAN"
if command -v fail2ban-client >/dev/null 2>&1; then
    "${SUDO[@]}" fail2ban-client status
    "${SUDO[@]}" fail2ban-client status sshd || true
else
    echo "[WARN] Fail2Ban is not installed."
fi

section "AUTOMATIC UPDATES"
if command -v systemctl >/dev/null 2>&1; then
    systemctl is-active unattended-upgrades || true
    systemctl is-enabled unattended-upgrades || true
fi

section "NETDATA"
if command -v systemctl >/dev/null 2>&1; then
    systemctl is-active netdata || true
fi
if command -v ss >/dev/null 2>&1; then
    "${SUDO[@]}" ss -lntp | grep ':19999' ||
        echo "[INFO] No listener found on port 19999."
fi

section "PENDING UPDATES"
if command -v apt >/dev/null 2>&1; then
    apt list --upgradable 2>/dev/null || true
else
    echo "[SKIP] apt is not available."
fi

section "LISTENING TCP PORTS"
if command -v ss >/dev/null 2>&1; then
    "${SUDO[@]}" ss -lntp
fi

section "DISK SPACE"
df -h /

section "AUDIT COMPLETE"
echo "Review the output manually. This script does not modify system settings."
