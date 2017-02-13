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

# System timezone
timezone --utc Asia/Taipei

# SELinux configuration
selinux disabled

# Network information
network --bootproto=dhcp --device=eth0 --noipv6 --activate --hostname InstallationHostname

# Root password
rootpw --iscrypted $6$Iu434Je.N7BcmXGj$uhFrG/mSWe8OjB0bB3n3cdw85gxcFh8NZ6TDN.kQmvs.Qg8sD5CQylmiVQQ3aB1OzBVl0MvILZf8GoKT4ddCy.

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

%packages --nocore
openssh-clients
openssh-server
yum
curl
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

sed -i '/GRUB_CMDLINE_LINUX=/s/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 net.ifnames=0 biosdevname=0"/' /mnt/sysimage/etc/default/grub
chroot /mnt/sysimage grub2-mkconfig -o /boot/grub2/grub.cfg

# Disable reverse dns lookups in ssh
sed -i '/UseDNS/s/.*/UseDNS no/' /mnt/sysimage/etc/ssh/sshd_config

# Classic networking
rm -f /mnt/sysimage/etc/sysconfig/network-scripts/ifcfg-enp*
cat << EOF > /mnt/sysimage/etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
NAME=eth0
BOOTPROTO=static
NM_CONTROLLED=no
ONBOOT=yes
TYPE=Ethernet
IPADDR=ServerIPAddress
GATEWAY=GatewayIP
DNS1=8.8.8.8
EOF

# Render yum repo configuration
mv /mnt/sysimage/etc/yum.repos.d{,.orig}
mkdir -p /mnt/sysimage/etc/yum.repos.d
cat << EOF > /mnt/sysimage/etc/yum.repos.d/centos.repo
[base]
name=Base
baseurl=http://iPXE_Server_IP/repo/centos/CentOSInstallationVersion/os/x86_64/
gpgcheck=0

[updates]
name=Updates
baseurl=http://iPXE_Server_IP/repo/centos/CentOSInstallationVersion/updates/x86_64/
gpgcheck=0
EOF

cat << EOF > /mnt/sysimage/etc/yum.repos.d/docker.repo
[dockerrepo]
name=Docker Repository
baseurl=http://iPXE_Server_IP/repo/centos/CentOSInstallationVersion/dockerrepo/
gpgcheck=0
EOF

# Install docker
chroot /mnt/sysimage yum install -y docker-engine
chroot /mnt/sysimage systemctl enable docker

# cloud-config to bash
curl -Lsk http://iPXE_Server_IP/cloud-config_to_bash/InstallationHostname-cloud-config_to_bash.tgz | tar -mzxC /root
rsync -avz /root/cloud-config_to_bash/ /mnt/sysimage/
for i in `ls /root/cloud-config_to_bash/etc/systemd/system`; do
    chroot /mnt/sysimage systemctl enable $i
done

# Install etcd
chroot /mnt/sysimage rpm -ivh http://iPXE_Server_IP/soft/etcd-2.3.7-4.el7.x86_64.rpm
export etcd_args=`cat /mnt/sysimage/root/etcd_args.txt`
sed -i "s#\(ExecStart=/bin/bash -c.*/usr/bin/etcd \).*#\1${etcd_args}\"#g" /mnt/sysimage/lib/systemd/system/etcd.service
echo "Alias=etcd2.service" >> /mnt/sysimage/usr/lib/systemd/system/etcd.service
chroot /mnt/sysimage systemctl enable etcd

%end
