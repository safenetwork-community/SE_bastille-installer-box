#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=base.sh

# stop on errors
set -eu

echo "==> ${NAME_SH}: Installing base system.."
/usr/bin/pacstrap ${ROOT_DIR} base &>/dev/null

echo "==> ${NAME_SH}: Updating pacman mirrors base installation.."
/usr/bin/arch-chroot ${ROOT_DIR} pacman -S --noconfirm reflector >/dev/null

/usr/bin/arch-chroot ${ROOT_DIR} reflector --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist >/dev/null
tee /etc/xdg/reflector/reflector.conf &>/dev/null <<EOF
--latest 5 
--protocol https
--sort rate
--save /etc/pacman.d/mirrorlist
EOF
/usr/bin/arch-chroot ${ROOT_DIR} systemctl enable reflector.timer >/dev/null

echo "==> ${NAME_SH}: Installing base development packages.."
/usr/bin/arch-chroot ${ROOT_DIR} pacman -S --noconfirm base-devel &>/dev/null

echo "==> ${NAME_SH}: Installing kernel.."
/usr/bin/arch-chroot ${ROOT_DIR} pacman -S --noconfirm linux >/dev/null

echo "==> ${NAME_SH}: Installing firmware.."
/usr/bin/arch-chroot ${ROOT_DIR} pacman -S --noconfirm linux-firmware >/dev/null

if [ "${FS_TYPE}" = "btrfs" ]; then
  /usr/bin/arch-chroot ${ROOT_DIR} pacman -S --noconfirm btrfs-progs >/dev/null
fi

echo "==> ${NAME_SH}: Generating the filesystem table.."
/usr/bin/genfstab -U ${ROOT_DIR} | tee -a "${ROOT_DIR}/etc/fstab" >/dev/null
