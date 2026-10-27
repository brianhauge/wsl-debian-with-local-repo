#!/bin/bash
# repo-upload [file.deb ...]   (no args: process everything in incoming/)
# Adds .deb files to the repo (codename: stable) and signs it.
# A file in incoming/ is renamed to .done-<name> only after reprepro succeeded;
# failed files are left untouched and the script exits non-zero.
set -uo pipefail
export GNUPGHOME=/srv/repo-gnupg
INC=/mnt/c/source/debian001/repo/incoming
cd /srv/repo
shopt -s nullglob
files=("$@"); [ ${#files[@]} -gt 0 ] || files=("$INC"/*.deb)
[ ${#files[@]} -gt 0 ] || { echo "no .deb files in $INC"; exit 0; }
fail=0
for f in "${files[@]}"; do
  [ -e "$f" ] || { echo "FAILED: $f does not exist"; fail=1; continue; }
  if reprepro -b /srv/repo -S misc -P optional includedeb stable "$f"; then
    echo "OK: $(basename "$f")"
    [ "$(dirname "$(readlink -f "$f")")" = "$INC" ] && mv "$f" "$INC/.done-$(basename "$f")"
  else
    echo "FAILED: $f (left in place)"; fail=1
  fi
done
reprepro -b /srv/repo list stable
exit $fail
