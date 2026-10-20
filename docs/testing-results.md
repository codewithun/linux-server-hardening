# Testing Results

## Environment

- OS: Ubuntu 24.04.5 LTS
- Hosting: Helipod
- SSH: External TCP 32200 mapped to internal TCP 22
- HTTP: External TCP 32080 mapped to internal TCP 80

## Verified Checks

- [x] SSH root login disabled
- [x] SSH password authentication disabled
- [x] SSH public-key authentication enabled
- [x] UFW active with default incoming deny
- [x] Fail2Ban SSH jail active
- [x] unattended-upgrades active and enabled
- [x] Netdata API returned HTTP 200 locally
- [x] Netdata listener restricted to 127.0.0.1:19999
- [x] Netdata dashboard accessible through SSH tunnel
- [x] Sudo requires authentication when its credential cache is cleared
- [x] Nginx, Docker, and Netdata services active

## Limitations

External network reachability and provider firewall behavior must
be tested separately. These checks do not constitute a full
penetration test or guarantee complete server security.
