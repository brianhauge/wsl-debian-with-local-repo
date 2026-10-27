#!/bin/bash
# Run in VM as root: re-sync repo config from this folder and re-sign.
set -euo pipefail
SRC=$(dirname "$(readlink -f "$0")")
export GNUPGHOME=/srv/repo-gnupg
KEYID=$(gpg --list-keys --with-colons | awk -F: '/^fpr/{print $10; exit}')
sed "s/@KEYID@/$KEYID/" $SRC/conf/distributions > /srv/repo/conf/distributions
install -m755 $SRC/upload.sh /usr/local/bin/repo-upload
