
#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=pacman.sh

# stop on errors
set -eu

echo "==> ${NAME_SH}: Installing databases.."
/usr/bin/arch-chroot ${ROOT_DIR} pacman -Sy >/dev/null

echo "==> ${NAME_SH}: Installing basic packages.."
/usr/bin/arch-chroot ${ROOT_DIR} pacman -S --noconfirm gptfdisk openssh dhcpcd >/dev/null
