#!/bin/bash
# Run inside the debian001 VM as root. Idempotent.
set -euo pipefail
SRC=$(dirname "$(readlink -f "$0")")
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends reprepro gnupg nginx ca-certificates dpkg-dev systemd systemd-sysv sudo curl >/dev/null

printf '[boot]\nsystemd=true\n' > /etc/wsl.conf

# signing key (no passphrase, test only)
export GNUPGHOME=/srv/repo-gnupg
if [ ! -d "$GNUPGHOME" ]; then
  mkdir -p "$GNUPGHOME"; chmod 700 "$GNUPGHOME"
  gpg --batch --pinentry-mode loopback --passphrase '' --quick-gen-key "debian001 repo <repo@debian001.local>" rsa3072 sign never
fi
mkdir -p /srv/repo/conf /srv/repo/incoming
bash "$SRC/reload.sh"
KEYID=$(gpg --list-keys --with-colons | awk -F: '/^fpr/{print $10; exit}')
gpg --export "$KEYID" > /srv/repo/debian001.gpg
gpg --armor --export "$KEYID" > /srv/repo/debian001.asc

cat > /etc/nginx/sites-available/default <<'NG'
server {
    listen 8080 default_server;
    root /srv/repo;
    autoindex on;
    location ~ ^/(conf|db|incoming)/ { deny all; }
}
NG
echo "deb [signed-by=/srv/repo/debian001.gpg] http://localhost:8080 stable main" > /etc/apt/sources.list.d/debian001.list
systemctl enable nginx >/dev/null 2>&1 || true
echo "provisioned; key $KEYID"
