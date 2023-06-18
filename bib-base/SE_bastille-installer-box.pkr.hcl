packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.9"
      source = "github.com/hashicorp/qemu"
    }
    virtualbox = {
      version = ">=1.0.4"
      source = "github.com/hashicorp/virtualbox"
    }
  }
}


variable "ssh_private_key_file" {
  type    = string
  default = "~/.ssh/id_bas"
}

variable "ssh_timeout" {
  type    = string
  default = "20m"

  validation {
      condition = can(regex("[0-9]+[smh]", var.ssh_timeout))
      error_message = "The ssh_timeout value must be a number followed by the letter s(econds), m(inutes), or h(ours)."
    }
}

variable "ssh_username" {
  description = "Unpriviledged user to create."
  type = string
  default = "bas"
}

locals {
  boot_command_qemu = [
    "<wait5><enter><wait2m>",
    "curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/${local.kickstart_script} && ",
    "chmod +x ${local.kickstart_script} && ",
    "LOCAL_IP={{ .HTTPIP }} ",
    "LOCAL_PORT={{ .HTTPPort }} ",
    "PACKER_BUILDER_TYPE=qemu ",
    "./${local.kickstart_script}<enter>",
  ]
  boot_command_virtualbox = [
    "<enter><wait90s>",
    "curl -O http://10.0.2.3:{{ .HTTPPort }}/${local.kickstart_script} && ",
    "chmod +x ${local.kickstart_script} && ",
    "LOCAL_IP=10.0.2.3 ",
    "LOCAL_PORT={{ .HTTPPort }} ",
    "PACKER_BUILDER_TYPE=iso-virtualbox ",
    "./${local.kickstart_script}<enter>",
  ]
  cpus              = 1
  disk_size         = "4G"
  disk_size_vb      = "4000"
  efi_firmware_code = "/usr/share/edk2/x64/OVMF_CODE.fd"
  efi_firmware_vars = "/usr/share/edk2/x64/OVMF_VARS.fd"
  headless          = "false"
  iso_checksum      = "sha256:329b00c3e8cf094a28688c50a066b5ac6352731ccdff467f9fd7155e52d36cec"
  iso_url           = "https://mirror.cj2.nl/archlinux/iso/2023.06.03/archlinux-x86_64.iso"
  kickstart_script  = "initLiveVM.sh"
  machine_type      = "q35"
  memory            = 4096
  http_directory    = "srv"
  vm_name           = "SE_bastille-installer-box"
  write_zeros       = "true"
}

source "qemu" "archlinux" {
  accelerator             = "kvm"
  boot_command            = local.boot_command_qemu
  boot_wait               = "1s"
  cpus                    = local.cpus
  disk_interface          = "virtio"
  disk_size               = local.disk_size
  efi_boot                = true
  efi_firmware_code       = local.efi_firmware_code
  efi_firmware_vars       = local.efi_firmware_vars
  format                  = "qcow2"
  headless                = local.headless
  http_directory          = local.http_directory
  iso_checksum            = local.iso_checksum
  iso_url                 = local.iso_url
  machine_type            = local.machine_type
  memory                  = local.memory
  net_device              = "virtio-net" 
  shutdown_command        = "sudo systemctl start poweroff.timer"
  ssh_handshake_attempts  = 500
  ssh_port                = 22
  ssh_private_key_file    = var.ssh_private_key_file
  ssh_timeout             = var.ssh_timeout
  ssh_username            = var.ssh_username
  ssh_wait_timeout        = var.ssh_timeout
  vm_name                 = "${local.vm_name}.qcow2"
}

source "virtualbox-iso" "archlinux" {  
    boot_command           = local.boot_command_virtualbox
    boot_wait              = "2s"  
    communicator           = "ssh"
    cpus                   = 1
    disk_size              = local.disk_size_vb
    firmware               = "efi"
    format                 = "ovf"  
    guest_additions_mode   = "disable"
    guest_os_type          = "Arch"
    hard_drive_interface   = "virtio"
    headless               = local.headless
    http_directory         = local.http_directory
    iso_checksum           = local.iso_checksum
    iso_interface          = "virtio"
    iso_url                = local.iso_url
    memory                 = local.memory
    nic_type               = "virtio"
    shutdown_command       = "sudo systemctl start poweroff.timer"
    ssh_port               = 22
    ssh_private_key_file   = var.ssh_private_key_file 
    ssh_timeout            = var.ssh_timeout
    ssh_username           = var.ssh_username  
    vm_name                = "${local.vm_name}.ovf"
}


build {
  name = "SE_bastille-installer-box"
  sources = ["source.qemu.archlinux", "source.virtualbox-iso.archlinux"]
  
  provisioner "file" {
    destination = "/tmp/"
    source      = "./files"
  }

  provisioner "shell" {
    only = ["qemu.archlinux"]
    execute_command = "{{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    expect_disconnect = true
    scripts           = [
    "scripts/liveVM.sh",
    "scripts/tables.sh",
    "scripts/partitions.sh",
    "scripts/base.sh",
    "scripts/bootloader.sh",
    "scripts/pacman.sh",
    "scripts/setup.sh"
    ]
  }
   
  provisioner "shell" {
    only = ["virtualbox-iso.archlinux"]
    execute_command = "{{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    expect_disconnect = true
    scripts           = [
    "scripts/liveVM.sh",
    "scripts/virtualbox.sh",
    "scripts/tables.sh",
    "scripts/partitions.sh",
    "scripts/base.sh",
    "scripts/bootloader.sh",
    "scripts/pacman.sh",
    "scripts/setup.sh"
    ]
  }

  provisioner "shell" {
    execute_command = "{{ .Vars }} WRITE_ZEROS=${local.write_zeros} sudo -E -S bash '{{ .Path }}'"
    script = "scripts/cleanup.sh"
  }
    
  post-processor "vagrant" {
    output = "output/${local.vm_name}_${source.type}_${source.name}-${formatdate("YYYY-MM", timestamp())}.box"
    vagrantfile_template = "templates/vagrantfile.tpl"
  }
}
