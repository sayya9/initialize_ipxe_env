mkdir -p /mnt/{nfs,rootfs/boot}
mount iPXE_Server_IP:pxelinux.cfg /mnt/nfs

# Remove PXE configuration
mac=`cat /root/installation_nic_mac`
macd=01-`echo ${mac,,} | tr ':' '-'`
cd /mnt/nfs
rm $macd

# Change Network Interface naming to tradition and mask update-engine.service
if grep -i coreos /etc/*-release; then
    mount /dev/[sv]da9 /mnt/rootfs
    mount /dev/[sv]da6 /mnt/rootfs/boot
    echo set linux_append="net.ifnames=0 biosdevname=0" > /mnt/rootfs/boot/grub.cfg
    mount --bind /usr /mnt/rootfs/usr
    chroot /mnt/rootfs systemctl mask update-engine
    umount -l /mnt/rootfs/usr
    umount -l /mnt/rootfs/boot
    umount -l /mnt/rootfs
    reboot
fi
