# Linux Server Hardening

A practical Linux server security project focused on reducing attack surface, strengthening SSH authentication, configuring firewall rules, preventing repeated SSH login attempts, and securing infrastructure monitoring.

## Overview

This project hardens an Ubuntu server while preserving existing services, including Nginx, Docker, and Netdata.

The configuration was applied and tested on an Ubuntu 24.04 LTS server hosted by Helipod.

## Objectives

- Disable direct SSH root login.
- Disable SSH password authentication and require public-key authentication.
- Restrict inbound network traffic using UFW.
- Configure Fail2Ban to protect SSH against repeated failed login attempts.
- Enable automatic security updates.
- Require password authentication for privileged `sudo` commands.
- Restrict Netdata to localhost and access its dashboard through an SSH tunnel.
- Provide a reusable security audit script.

## Architecture

```text
Administrator (Mac)
       |
       | SSH key authentication
       | External TCP port 32200
       v
Ubuntu Server
       |
       +-- SSH: internal port 22
       +-- Nginx: internal port 80
       +-- Docker
       +-- Netdata: 127.0.0.1:19999
       |
       +-- UFW
       +-- Fail2Ban
       +-- unattended-upgrades
```

The external SSH and HTTP ports are mapped to internal ports by the hosting provider. These mappings are provider-specific and are not configured by UFW itself.

## Security Controls

### 1. SSH Hardening

The effective SSH configuration was verified with `sshd -T`.

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 4
```

These settings prevent direct root login, disable password-based SSH authentication, require public-key authentication, and limit authentication attempts per connection.

### 2. UFW Firewall

The firewall was configured with:

- Default incoming policy: deny.
- Default outgoing policy: allow.
- Default routed policy: deny.
- Allow inbound TCP port 22 for SSH.
- Allow inbound TCP port 80 for HTTP.

The hosting provider must forward external ports to the corresponding internal services.

### 3. Fail2Ban

Fail2Ban was installed and enabled with the `sshd` jail.

The audit recorded two previously banned IP addresses. This confirms that bans had occurred, but does not guarantee that every attack will be blocked.

### 4. Automatic Security Updates

The `unattended-upgrades` service was enabled and active.

The pending package update found during the audit was installed, and a subsequent package check showed no pending upgrades.

### 5. Netdata Access Restriction

Netdata was initially listening on all network interfaces. Its web configuration was changed to:

```ini
[web]
    bind to = 127.0.0.1 ::1
```

After restarting the service, the listener was verified on `127.0.0.1:19999`, and the local API returned HTTP 200.

The dashboard was successfully accessed through an SSH tunnel:

```bash
ssh -N -L 19999:127.0.0.1:19999 roadmap-server
```

Open `http://127.0.0.1:19999` in the administrator's browser while the tunnel remains active.

### 6. Sudo Authentication

The `NOPASSWD` rule was removed from the Ubuntu user's sudo configuration.

Validation included:

- `visudo -cf /etc/sudoers` completed successfully.
- `sudo -v` succeeded after password authentication.
- `sudo -k` followed by `sudo -n whoami` returned `sudo: a password is required`.

This confirms that privileged commands require fresh authentication when no valid sudo credential cache exists.

## Project Structure

```text
linux-server-hardening/
├── README.md
├── scripts/
│   └── security-audit.sh
├── configs/
│   ├── ssh-hardening.conf
│   └── netdata.conf
└── docs/
    └── testing-results.md
```

## Requirements

- Ubuntu Server 24.04 LTS or compatible Ubuntu release.
- Administrative access through a non-root user with sudo privileges.
- SSH key authentication.
- UFW, Fail2Ban, and unattended-upgrades.
- Netdata, if monitoring access restriction is required.

## Security Audit

Run the audit script on the target Ubuntu server:

```bash
chmod +x scripts/security-audit.sh
./scripts/security-audit.sh
```

The script reports effective SSH settings, firewall status, Fail2Ban status, automatic updates, Netdata listeners, and pending package updates. It does not automatically change server configuration.

## Important Notes

- Review the hosting provider's network firewall and port forwarding separately from UFW.
- Keep an active administrative session and a provider console available during SSH or firewall changes.
- Never commit private SSH keys, passwords, tokens, server credentials, or sensitive configuration backups.
- The example configuration files in this repository are reference configurations and should be reviewed before deployment.
- Security settings reduce risk but do not guarantee complete protection.

## Status

Core hardening and the initial verification steps were completed on the test server. The audit script and repository documentation should be reviewed and tested before considering the GitHub release complete.
