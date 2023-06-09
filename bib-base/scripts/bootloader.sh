#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=bootloader.sh

# stop on errors
set -eu

echo "==> ${NAME_SH}: Installing grub packages.."
/usr/bin/arch-chroot ${ROOT_DIR} /usr/bin/pacman --noconfirm -S edk2-ovmf efibootmgr grub os-prober >/dev/null

echo "==> ${NAME_SH}: Pre-configure grub.."
/usr/bin/arch-chroot ${ROOT_DIR} sed -i 's/#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/' /etc/default/grub

echo "==> ${NAME_SH}: Installing grub.."
/usr/bin/arch-chroot ${ROOT_DIR} grub-install --target=x86_64-efi --efi-directory=${ESP_DIR} --bootloader-id=GRUB &>/dev/null
/usr/bin/arch-chroot ${ROOT_DIR} grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null

echo "==> ${NAME_SH}: Check boots.."
/usr/bin/arch-chroot ${ROOT_DIR} efibootmgr
