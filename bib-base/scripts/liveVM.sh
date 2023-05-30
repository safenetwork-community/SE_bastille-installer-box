#!/usr/bin/bash

. /root/vars.sh

NAME_SH=liveVM.sh
GRUB=/etc/default/grub

# stop on errors
set -eu

echo "==> ${NAME_SH}: Lock root password.."
/usr/bin/passwd -l root >/dev/null

echo "==> ${NAME_SH}: Update the system clock.."
/usr/bin/pacman --noconfirm -Sy ntp >/dev/null
/usr/bin/systemctl start ntpd >/dev/null

echo "==> ${NAME_SH}: Modifying local settings.."
/usr/bin/ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime
echo ${HOST_LIVEVM_NAME} | tee /etc/hostname >/dev/null

echo "==> ${NAME_SH}: Installing packages for commands used in provisioner scripts.."
/usr/bin/pacman --noconfirm -Sy pacman-contrib >/dev/null

echo "==> ${NAME_SH}: Reranking pacman mirrorslist.."
/usr/bin/cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup   
/usr/bin/rankmirrors -v -n 5 /etc/pacman.d/mirrorlist-backup | tee /etc/pacman.d/mirrorlist >/dev/null
/usr/bin/rm -rf /etc/pacman.d/mirrorlist-backup
