timeout 5
default iPXE
LABEL iPXE
KERNEL ipxe.krn
APPEND dhcp && chain http://iPXE_Server_IP/ipxe/boot.ipxe
