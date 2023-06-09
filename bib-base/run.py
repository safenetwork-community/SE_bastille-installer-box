#!/usr/bin/env python

from pathlib import Path
import subprocess, os

command = "packer"
subcommand = "build"

# Environment variables
packer_env = os.environ.copy()
packer_env["PACKER_LOG"] = "1"

# File names
template = "SE_bastille-installer-box.pkr.hcl"
vm_name = "SE_bastille-installer-box_qemu_archlinux-2023-06.qcow2"

# Folder locations
path_output = "./output"
path_output_os = "./output-artix"
path_virt_manager = "/var/lib/libvirt/images/"

# File locations
location_vm_old = f"{path_output}/{vm_name}"
location_vm_new = f"{path_virt_manager}/{vm_name}"

# delete output folder if it exists
if Path(path_output).is_dir(): 
    subprocess.run(["rm", "-r", path_output])

# delete os output folder if it exists
if Path(path_output_os).is_dir(): 
    subprocess.run(["rm", "-r", path_output_os])



# Run packer
args = [command, subcommand, template]
print(' '.join(args)) 
subprocess.run(args, env=packer_env)

# Move box to virt-manager 
if Path(path_output).exists() and Path(path_output).is_dir():  
    subprocess.run(["sudo", "qemu-img", "info", location_vm_old])
    # subprocess.run(["sudo", "chown", "libvirt-qemu:libvirt-qemu", location_vm_old])
    # subprocess.run(["sudo", "chmod", "600", location_vm_old])
    # subprocess.run(["sudo", "mv", location_vm_old, location_vm_new])
    #subprocess.run(["sudo", "virt-install",
    #                "--name", "bastille-installer",
    #                "--vcpu", "2",
    #                "--memory", "1024",
    #                "--osinfo", "archlinux",
    #                "--disk", location_vm_new, 
    #                "--import",
    #                "--boot", "uefi"])
