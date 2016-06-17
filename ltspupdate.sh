#! /bin/sh

## Ensure unmounted
umount /opt/ltsp/amd64/proc

## Update keys
ltsp-update-sshkeys
## Update Kernals
ltsp-update-kernels
## Update LTSP Image
ltsp-update-image amd64
## Update PXE for Ubuntu
sed -i 's/ipappend 2/ipappend 3/g' /var/lib/tftpboot/ltsp/amd64/pxelinux.cfg/default
