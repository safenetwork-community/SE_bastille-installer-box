#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=base.sh

# stop on errors
set -eu

echo "==> ${NAME_SH}: Installing base system.."
/usr/bin/pacstrap ${ROOT_DIR} base base-devel &>/dev/null

if [ "${FS_TYPE}" = "btrfs" ]; then
  /usr/bin/pacstrap ${ROOT_DIR} btrfs-progs
fi

echo "==> ${NAME_SH}: Installing kernel.."
/usr/bin/pacstrap ${ROOT_DIR} linux linux-firmware >/dev/null

echo "==> ${NAME_SH}: Generating the filesystem table.."
/usr/bin/genfstab -U ${ROOT_DIR} | tee -a "${ROOT_DIR}/etc/fstab" >/dev/null
