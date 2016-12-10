timeout 10
default iPXE
LABEL iPXE
KERNEL ipxe.krn
APPEND dhcp && chain http://192.168.56.90/ipxe/boot.ipxe
