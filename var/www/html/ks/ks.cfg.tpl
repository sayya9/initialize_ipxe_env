#version=DEVEL
# System authorization information
auth --enableshadow --passalgo=sha512

# Use network installation
url --url=http://iPXE_Server_IP/repo/centos/CentOSInstallationVersion/os/x86_64

# Use text mode install
text
# Run the Setup Agent on first boot
firstboot --disable
ignoredisk --only-use=sda

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_US.UTF-8

# SELinux configuration
selinux disabled

# Network information
network  --bootproto=dhcp --device=enp0s3 --ipv6=auto --activate --hostname InstallationHostname

# Root password
rootpw --iscrypted $6$Iu434Je.N7BcmXGj$uhFrG/mSWe8OjB0bB3n3cdw85gxcFh8NZ6TDN.kQmvs.Qg8sD5CQylmiVQQ3aB1OzBVl0MvILZf8GoKT4ddCy.

# System timezone
timezone Asia/Taipei --isUtc

# System bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda

# Partition clearing information
clearpart --all --initlabel --drives=sda

# Disk partitioning information
part /boot --fstype="xfs" --ondisk=sda --size=500
part pv.01 --fstype="lvmpv" --ondisk=sda --size=4096 --maxsize=51200 --grow
volgroup vg_root --pesize=4096 pv.01
logvol swap  --fstype="swap" --size=1024 --name=lv_swap --vgname=vg_root
logvol /  --fstype="xfs" --grow --size=1024 --maxsize=51200 --name=lv_root --vgname=vg_root

# Reboot afer installing
reboot

%packages --nobase
@core --nodefaults
%end

%addon com_redhat_kdump --enable --reserve-mb='auto'
%end

%pre --log=/mnt/sysimage/root/ks-pre.log
cat > /root/installation_nic_mac << EOF
MACAddress
EOF
%end

%post --nochroot --log=/mnt/sysimage/root/ks-post.log
/bin/bash -c 'wget -O - http://iPXE_Server_IP/bin/ipxe-cleand.sh | bash -ex -'
%end
