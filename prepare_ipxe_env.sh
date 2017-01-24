#!/bin/bash -e

K8SVersion=1.5.2
CoreOSInstallationVersion=1235.6.0
iPXE_Server_IP=192.168.56.90
RouterIP=192.168.56.1
ethX=eth1
PrepareDir=$PWD

# Create necessary directories
mkdir -p /var/www/html/{ipxe,k8s}
mkdir -p /var/www/html/k8s/manifests
mkdir -p /var/www/html/images/{docker,coreos/amd64-usr/${CoreOSInstallationVersion}} /etc/dhcp/template
mkdir -p /var/tftpboot /root/bin

UpdateConf() {
  Subnet=${iPXE_Server_IP%.*}.0
  Netmask=255.255.255.0
  Range1=${iPXE_Server_IP%.*}.181
  Range2=${iPXE_Server_IP%.*}.190
  Broadcast=${iPXE_Server_IP%.*}.255

  cat > etc/dhcp/dhcpd.conf << EOF
ddns-update-style none;
option domain-name "example.org";
option domain-name-servers 8.8.8.8;
default-lease-time 600;
max-lease-time 7200;
log-facility local7;

subnet $Subnet netmask $Netmask {
  range $Range1 $Range2;
  option routers $RouterIP;
  option broadcast-address $Broadcast;
  next-server $iPXE_Server_IP;
  filename = "pxelinux.0";
}

EOF

  cat > /var/www/html/ipxe/boot.ipxe.tpl << EOF
#!ipxe

set base-url http://${iPXE_Server_IP}/images/coreos/amd64-usr/${CoreOSInstallationVersion}
kernel \${base-url}/vmlinuz cloud-config-url=http://${iPXE_Server_IP}/cloud-configs/ipxe_stage/InstallationHostname-ipxe-cloud-config.yml coreos.autologin
initrd \${base-url}/cpio.gz
boot
EOF

  cat > /var/tftpboot/pxelinux.cfg/by_mac.tpl << EOF
timeout 5
default iPXE
LABEL iPXE
KERNEL ipxe.krn
APPEND dhcp && chain http://iPXE_Server_IP/ipxe/InstallationHostname.ipxe
EOF

  cp -f systemd-conf/* /etc/systemd/system
  systemctl daemon-reload
  for i in nfs-server nginx tftp; do
      systemctl enable $i
      systemctl restart $i
  done

  rsync -avz --delete root/bin/ /root/bin/
  rsync -avz --delete var/www/html/bin/ /var/www/html/bin/
  rsync -avz --delete var/www/html/cloud-configs/ /var/www/html/cloud-configs/
  rsync -avz --delete var/www/html/k8s/ /var/www/html/k8s/
  rsync -avz --delete var/www/html/bin/ /var/www/html/bin/
  rsync -avz --delete var/www/html/scripts/ /var/www/html/scripts/
  rsync -avz --delete var/www/html/soft/ /var/www/html/soft/
  rsync -avz --delete var/www/html/special_case/ /var/www/html/special_case/
  rsync -avz var/tftpboot/ /var/tftpboot/
  rsync -avz etc/dhcp/ /etc/dhcp/

  WebDir=/var/www/html
  sed -i "s/ethX/$ethX/g" /etc/systemd/system/dhcp.service
  sed -i "s/K8SVersion/$K8SVersion/g" ${WebDir}/bin/* ${WebDir}/scripts/*
  sed -i "s/iPXE_Server_IP/$iPXE_Server_IP/g" ${WebDir}/bin/* ${WebDir}/scripts/*
  sed -i "s/iPXE_Server_IP/$iPXE_Server_IP/g" ${WebDir}/cloud-configs/template/* 
  sed -i "s/iPXE_Server_IP/$iPXE_Server_IP/g" /var/tftpboot/pxelinux.cfg/by_mac.tpl
  sed -i "s/RouterIP/$RouterIP/g" ${WebDir}/cloud-configs/template/*

  # gather kubernetes manifests
  dir=var/www/html/k8s
  repositoies=(https://github.com/jaohaohsuan/heketi-kubernetes-deploy,heketi-kubernetes-deploy)

  OrigIFS=$IFS
  rm -rfv /var/www/html/k8s/manifests/
  for i in $repositoies; do
    IFS=","; set $i;
    local url=$1
    local repo=${dir}/$2
    if [ -d "${repo}/.git" ]; then
      cd $repo
      git pull
      cd $PrepareDir
    else
      git clone $url $repo
    fi
    rsync -avz ${repo}/manifests/ /var/www/html/k8s/manifests/
  done
  IFS=$OrigIFS

  # tar all kubernetes manifests
  cd /var/www/html/k8s
  tar -zcvf /var/www/html/k8s/manifests.tar.gz manifests
  cd $PrepareDir
}

if [ "$1" == "-s" ]; then
    UpdateConf
    exit 0
fi

# pull ipxe environment service images
docker pull networkboot/dhcpd
docker pull nginx:stable-alpine
docker pull cpuguy83/nfs-server
docker pull pghalliday/tftp


# Add docker repository and install docker
if ! apt-cache policy | grep -q "apt.dockerproject.org"; then
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" >> /etc/apt/sources.list
fi
apt-key update
apt-get update
apt-get install -y docker-engine

# Download rkt's hyperkube image
# if ! [ -d /var/www/html/images/rkt/hyperkube/v${K8SVersion}_coreos.0 ]; then
#     mkdir -p /var/www/html/images/rkt/hyperkube/v${K8SVersion}_coreos.0
# fi
# wget -c https://quay.io/c1/aci/quay.io/coreos/hyperkube/v${K8SVersion}_coreos.0/aci/linux/amd64/ -O /var/www/html/images/rkt/hyperkube/v${K8SVersion}_coreos.0/hyperkube.aci
# wget -c https://quay.io/c1/aci/quay.io/coreos/hyperkube/v${K8SVersion}_coreos.0/aci.asc/linux/amd64/ -O /var/www/html/images/rkt/hyperkube/v${K8SVersion}_coreos.0/hyperkube.aci.asc

# Download coreos_production_iso_image.iso to get vmlinuz, cpio.gz and pxelinux.0
wget -c -P /root https://stable.release.core-os.net/amd64-usr/current/coreos_production_iso_image.iso
mount /root/coreos_production_iso_image.iso /mnt
cp -f /mnt/coreos/* /var/www/html/images/coreos/amd64-usr/${CoreOSInstallationVersion}
cp -f /mnt/isolinux/pxelinux.0 /var/tftpboot
umount /mnt

# Download ipxe.iso to get ipxe.krn
wget -c -P /root http://boot.ipxe.org/ipxe.iso
mount /root/ipxe.iso /mnt
cp -f /mnt/ipxe.krn /var/tftpboot
umount /mnt

# Download necessary files
wget -c -P /var/www/html/images/coreos/amd64-usr/${CoreOSInstallationVersion} https://stable.release.core-os.net/amd64-usr/${CoreOSInstallationVersion}/coreos_production_image.bin.bz2
wget -c -P /var/www/html/images/coreos/amd64-usr/${CoreOSInstallationVersion} https://stable.release.core-os.net/amd64-usr/${CoreOSInstallationVersion}/coreos_production_image.bin.bz2.sig
wget -c -P /var/www/html/soft http://downloads.activestate.com/ActivePython/releases/2.7.10.12/ActivePython-2.7.10.12-linux-x86_64.tar.gz
# wget -c -P /var/www/html/soft https://dl.k8s.io/network-plugins/cni-amd64-07a8a28637e97b22eb8dfe710eeae1344f69d16e.tar.gz
# wget -c -P /var/www/html/soft https://storage.googleapis.com/kubernetes-release-dev/ci-cross/v1.5.0-alpha.2.421+a6bea3d79b8bba/bin/linux/amd64/kubeadm

# build kubeadm
cd kubeadm
`pwd`/build $K8SVersion
cd $PrepareDir

# update k8s version
set -x
sed -i 's/\(hyperkube-amd64:\|kubeadm:\)v[0-9]\+\.[0-9]\+\.[0-9]\+/\1v'$K8SVersion'/g' prod-images
set +x

# pull and tar image
true > /var/www/html/images/docker-list
while read -r line
do
    img="$line"
    docker pull $img
    tar_filename=`echo ${img##*/} | tr ':' '_'`.tar
    echo "Saving $img to $tar_filename"
    docker save $img > /var/www/html/images/docker/$tar_filename
    echo "$tar_filename" >> /var/www/html/images/docker-list
done < "./prod-images"

UpdateConf
