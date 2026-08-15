# Copyright (C) 2026 Fronttier Labs
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

#!/bin/bash
# mkstage.sh v3 - build a clean Fronttier stage tarball from a staging copy
set -euo pipefail

START=$(date +%s)

NAME="fronttier-stage1-$(date +%Y%m%d)"
OUT="/tmp/${NAME}.tar.xz"
STAGE="/tmp/stage-clean"
S="$STAGE"

WITH_DESKTOP=0
KEEP_USERS=0
SLIM=1
while [ $# -gt 0 ]; do
  case "$1" in
    --with-desktop) WITH_DESKTOP=1 ;;
    --keep-users)   KEEP_USERS=1 ;;
    --slim)         SLIM=1 ;;
    --full)         SLIM=0 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
  shift
done

echo ">> preparing staging tree at $STAGE"
rm -rf "$STAGE" && mkdir -p "$STAGE"

EXCLUDES=(
  --exclude='./proc' --exclude='./sys' --exclude='./dev' --exclude='./run'
  --exclude='./tmp' --exclude='./mnt' --exclude='./media' --exclude='./lost+found'
  --exclude='./opt/xbps-packages' --exclude='./var/lib/flatpak'
  --exclude='./var/cache' --exclude='./usr/src' --exclude='./swapfile'
  --exclude='./usr/share/info'
  --exclude='./usr/libexec/valgrind'
)
[ "$WITH_DESKTOP" -eq 0 ] && EXCLUDES+=(--exclude='./opt/voidroot')

SLIM_EXCLUDES=(
 
--exclude='./usr/share/info'
--exclude='./usr/libexec/valgrind'
 --exclude='./usr/share/doc'
  --exclude='./usr/share/man'
  --exclude='./usr/share/gtk-doc'
  --exclude='./usr/lib/python3.14/test'
  --exclude='./usr/lib/valgrind'
  --exclude='./usr/share/locale'
  --exclude='./usr/lib/locale'
  --exclude='./usr/share/info'
  --exclude='./usr/libexec/valgrind'
  --exclude='./boot/grub/locale'
)
[ "$SLIM" -eq 1 ] && EXCLUDES+=("${SLIM_EXCLUDES[@]}")

echo ">> copying live root -> staging"
cd / && tar --warning=no-timestamp -cJf /tmp/.stage-pipe.tar.xz "${EXCLUDES[@]}" .
tar -xJpf /tmp/.stage-pipe.tar.xz -C "$STAGE" --numeric-owner
rm -f /tmp/.stage-pipe.tar.xz

echo ">> purging ephemeral"
: > "$S/etc/machine-id"
echo fronttier > "$S/etc/hostname"
find "$S/var/log" -type f -exec truncate -s 0 {} + 2>/dev/null || true
rm -rf "$S/var/cache"/* "$S/var/tmp"/* 2>/dev/null || true
rm -rf "$S/root/.config" "$S/root/.ssh" "$S/root/.gnupg" \
       "$S/root/.local" "$S/root/.cache" "$S/root/.dbus" "$S/root/.var"
rm -f  "$S/root/.bash_history" "$S/root/.sh_history" "$S/root/.ksh_history" \
       "$S/root/.python_history" "$S/root/.lesshst" "$S/root/.wget-hsts" \
       "$S/root/.Xauthority" "$S/root/.ICEauthority" "$S/root/.netrc"

if [ "$KEEP_USERS" -eq 0 ]; then
  RELEASE_USER="${RELEASE_USER:-user}"
  for u in $(awk -F: -v keep="$RELEASE_USER" '$3>=1000 && $1!=keep {print $1}' "$S/etc/passwd"); do
    for f in passwd shadow group gshadow; do
      [ -f "$S/etc/$f" ] && sed -i "/^$u:/d" "$S/etc/$f"
    done
    rm -rf "$S/home/$u"
  done

  # sanitize the release user's home: keep it skeleton-clean
  UH="$S/home/$RELEASE_USER"
  rm -rf "$UH/.config" "$UH/.cache" "$UH/.local" "$UH/.dbus" "$UH/.var"
  rm -f  "$UH/.bash_history" "$UH/.lesshst" "$UH/.wget-hsts" "$UH/.python_history" "$UH/.Xauthority"
fi


[ -f "$S/etc/shadow" ] && sed -i 's|^root:[^:]*:|root:*:|' "$S/etc/shadow"

if [ "$WITH_DESKTOP" -eq 1 ]; then
  V="$S/opt/voidroot"
  rm -rf "$V/root/.ssh" "$V/root/.config" "$V/root/.gnupg"
  rm -rf "$V/home/void/.cache" "$V/home/void/.config" "$V/home/void/.local" \
         "$V/home/void/.var" "$V/home/void/.pulse"
  rm -f  "$V/home/void/.Xauthority"
fi

echo ">> packing clean stage"
tar -cJpf "$OUT" -C "$STAGE" --numeric-owner .
sha256sum "$OUT" > "$OUT.sha256"
du -h "$OUT"

END=$(date +%s)
ELAPSED=$((END - START))
printf ">> build time: %dm %02ds\n" $((ELAPSED / 60)) $((ELAPSED % 60))
echo ">> done: $OUT"
echo ">> sha256 written: $OUT.sha256"
