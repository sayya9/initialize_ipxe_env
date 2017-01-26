mkdir -p /mnt/{nfs,rootfs/boot}
mount iPXE_Server_IP:/pxelinux.cfg /mnt/nfs

# Bind NIC device to ethX
mount /dev/sda6 /mnt/rootfs/boot
echo set linux_append="net.ifnames=0 biosdevname=0" > /mnt/rootfs/boot/grub.cfg

# Remove PXE configuration
mac=`cat /root/installation_nic_mac`
macd=01-`echo ${mac,,} | tr ':' '-'`
cd /mnt/nfs
rm $macd

reboot
