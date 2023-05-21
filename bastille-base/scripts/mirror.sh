#!/usr/bin/bash

. /tmp/files/vars.sh

NAME_SH=mirror.sh

# stop on errors
set -eu

# lock root password
passwd -l root

echo "==> ${NAME_SH}: Setting pacman mirrors of liveVM.."
/usr/bin/pacman -Sy
# /usr/bin/reflector --country Netherlands,Belgium --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
