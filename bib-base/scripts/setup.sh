#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=setup.sh

# stop on errors
set -eu

echo "==> ${NAME_SH}: Generating the system configuration script.."
/usr/bin/install --mode=0755 /dev/null "${ROOT_DIR}${CONFIG_SCRIPT}"

CONFIG_SCRIPT_SHORT=`basename "$CONFIG_SCRIPT"`
tee "${ROOT_DIR}${CONFIG_SCRIPT}" &>/dev/null << EOF
  echo "==> ${CONFIG_SCRIPT_SHORT}: Configuring hostname, timezone, and keymap.."
  echo '${HOSTNAME_BOX}' | tee /etc/hostname >/dev/null
  /usr/bin/ln -s /usr/share/zoneinfo/${TIMEZONE_BOX} /etc/localtime
  echo 'KEYMAP=${KEYMAP_BOX}' | tee /etc/vconsole.conf >/dev/null
  echo "==> ${CONFIG_SCRIPT_SHORT}: Configuring locale.."
  /usr/bin/sed -i 's/#${LANGUAGE_BOX}/${LANGUAGE_BOX}/' /etc/locale.gen
  /usr/bin/locale-gen >/dev/null
  echo "==> ${CONFIG_SCRIPT_SHORT}: Creating initramfs.."
  /usr/bin/mkinitcpio -p linux &>/dev/null
  echo "==> ${CONFIG_SCRIPT_SHORT}: Setting root pasword.."
  /usr/bin/usermod --password ${ROOT_PASSWORD} root
  echo "==> ${CONFIG_SCRIPT_SHORT}: Configuring network.."
  # Disable systemd Predictable Network Interface Names and revert to traditional interface names
  # https://wiki.archlinux.org/index.php/Network_configuration#Revert_to_traditional_interface_names
  /usr/bin/ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
  /usr/bin/systemctl enable dhcpcd@eth0.service &>/dev/null
  echo "==> ${CONFIG_SCRIPT_SHORT}: Configuring sshd.."
  /usr/bin/sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
  /usr/bin/systemctl enable sshd.service &>/dev/null
  # Workaround for https://bugs.archlinux.org/task/58355 which prevents sshd to accept connections after reboot
  echo "==> ${CONFIG_SCRIPT_SHORT}: Adding workaround for sshd connection issue after reboot.."
  /usr/bin/pacman -S --noconfirm rng-tools >/dev/null
  /usr/bin/systemctl enable rngd &>/dev/null
  echo "==> ${CONFIG_SCRIPT_SHORT}: Enable time synching.."
  /usr/bin/pacman -S --noconfirm ntp >/dev/null 
  /usr/bin/systemctl enable ntpd &>/dev/null
  echo "==> ${CONFIG_SCRIPT_SHORT}: Installing ${ISCR} non-AUR dependencies.."
  /usr/bin/pacman -S --noconfirm wget git parted >/dev/null
  /usr/bin/pacman -S --noconfirm dialog dosfstools f2fs-tools polkit qemu-user-static-binfmt >/dev/null 
  # Vagrant user apparently created through pacstrap for Arch Linux.
  echo "==> ${CONFIG_SCRIPT_SHORT}: Modifying vagrant user.."
  /usr/bin/useradd --comment 'Vagrant User' -d /home/${USER_NAME} --user-group ${USER_GROUP}
  /usr/bin/echo -e "${USER_PASSWORD}\n${USER_PASSWORD}" | /usr/bin/passwd ${USER_NAME} &>/dev/null
  echo "==> ${CONFIG_SCRIPT_SHORT}: Configuring sudo.."
  echo "Defaults env_keep += \"SSH_AUTH_SOCK\"" | tee /etc/sudoers.d/10_${USER_NAME} &>/dev/null
  echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers.d/10_${USER_NAME} &>/dev/null
  /usr/bin/chmod 0440 /etc/sudoers.d/10_${USER_NAME}
  echo "==> ${CONFIG_SCRIPT_SHORT}: Cleaning up.."
  /usr/bin/pacman -Rcns --noconfirm gptfdisk >/dev/null
EOF

echo "==> ${NAME_SH}: Entering chroot and configuring system.."
/usr/bin/arch-chroot ${ROOT_DIR} ${CONFIG_SCRIPT}
rm "${ROOT_DIR}${CONFIG_SCRIPT}"

echo "==> ${NAME_SH}: Creating ssh access for ${USER_NAME}.."
/usr/bin/install --directory --owner=${USER_NAME} --group=${USER_GROUP} --mode=0700 ${ROOT_DIR}${USER_SSH_DIR}
/usr/bin/install --owner=${USER_NAME} --group=${USER_GROUP} --mode=0600 ${USER_KEYS_PATH} ${ROOT_DIR}${USER_KEYS_PATH}

# http://comments.gmane.org/gmane.linux.arch.general/48739
echo "==> ${NAME_SH}: Adding workaround for shutdown race condition.."
/usr/bin/install --mode=0644 ${TMP_FILES_DIR}/poweroff.timer "${ROOT_DIR}/etc/systemd/system/poweroff.timer"

echo "==> ${NAME_SH}: Trimming partition sizes.."
/usr/bin/fstrim ${BOOT_DIR}
/usr/bin/fstrim ${ROOT_DIR}

echo "==> ${NAME_SH}: Completing installation.."
/usr/bin/umount ${BOOT_DIR}
/usr/bin/umount ${ROOT_DIR}
/usr/bin/rm -rf ${USER_SSH_DIR}

# Turning network interfaces down to make sure SSH session was dropped on host.
# More info at: https://www.packer.io/docs/provisioners/shell.html#handling-reboots
echo '==> Turning down network interfaces and rebooting'
for i in $(/usr/bin/ip -o link show | /usr/bin/awk -F': ' '{print $2}'); do /usr/bin/ip link set ${i} down; done
/usr/bin/systemctl reboot
echo "==> ${NAME_SH}: Installation complete!"
