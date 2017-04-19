#!/bin/bash -ex

K8SVersion=1.5.6
CoreOSInstallationVersion=1235.6.0
CentOSInstallationVersion=7
DeployCoreOS=yes
DeployCentOS=no
IsChina=no
iPXE_Server_IP=192.168.56.90
GatewayIP=192.168.56.1
ethX=eth1
PrepareDir=$PWD

CoreOSEnv() {
    # Download coreos_production_iso_image.iso to get vmlinuz and cpio.gz
    wget -c -P /root https://stable.release.core-os.net/amd64-usr/current/coreos_production_iso_image.iso
    tempDir=/mnt/coreos_production_iso_image
    mkdir -p $tempDir
    if ! grep -q $tempDir /proc/mounts; then
        mount /root/coreos_production_iso_image.iso $tempDir
    fi
    mkdir -p /var/www/html/images/coreos/amd64-usr/${CoreOSInstallationVersion}
    cp -f ${tempDir}/coreos/* /var/www/html/images/coreos/amd64-usr/${CoreOSInstallationVersion}
    umount $tempDir

    # Download necessary files
    wget -c -P /var/www/html/images/coreos/amd64-usr/${CoreOSInstallationVersion} https://stable.release.core-os.net/amd64-usr/${CoreOSInstallationVersion}/coreos_production_image.bin.bz2
    wget -c -P /var/www/html/images/coreos/amd64-usr/${CoreOSInstallationVersion} https://stable.release.core-os.net/amd64-usr/${CoreOSInstallationVersion}/coreos_production_image.bin.bz2.sig
}

CentOSEnv() {
    # Download CentOS iso
    curl http://isoredirect.centos.org/centos/${CentOSInstallationVersion}/isos/x86_64/ > /tmp/tempfile.txt
    CentOSURL=`cat /tmp/tempfile.txt | sed -n 's#.*\(http://.*/isos/x86_64/\).*#\1#p' | head -n 1`
    curl $CentOSURL > /tmp/tempfile.txt
    FileName=`cat /tmp/tempfile.txt | sed -n '/CentOS-.*-x86_64-DVD.*.iso/s/.*\(CentOS-.*-x86_64-DVD.*.iso\).*/\1/p'`
    wget -c -P /root ${CentOSURL}${FileName}

    # Mount iso to base repo directory
    repoParentDir=/var/www/html/repo/centos
    repoBaseDir=${repoParentDir}/${CentOSInstallationVersion}/os/x86_64
    mkdir -p $repoBaseDir
    if ! grep -q $repoBaseDir /proc/mounts; then
        mount /root/${FileName} $repoBaseDir
    fi

    # Download updates and docker repo rpm packages
    repoUpdatesDir=${repoParentDir}/${CentOSInstallationVersion}/updates/x86_64
    repoDockerDir=${repoParentDir}/${CentOSInstallationVersion}/dockerrepo
    mkdir -p $repoUpdatesDir $repoDockerDir
    docker pull centos:7
    docker run -v ${repoUpdatesDir}:/tmp/updates/x86_64 -v ${repoDockerDir}:/tmp/dockerrepo -v ${PrepareDir}/yum/docker.repo:/etc/yum.repos.d/docker.repo --rm -it centos:7 bash -c "reposync -r updates -p /tmp/updates/x86_64 --norepopath && reposync -r dockerrepo -p /tmp/dockerrepo --norepopath && yum install -y createrepo && createrepo -v /tmp/updates/x86_64 && createrepo -v /tmp/dockerrepo"

    # Download etcd rpm
    wget -N -P /var/www/html/soft ${CentOSURL%isos/*/}extras/x86_64/Packages/etcd-2.3.7-4.el7.x86_64.rpm
}

UpdateConf() {
    Subnet=${iPXE_Server_IP%.*}.0
    Netmask=255.255.255.0
    Range1=${iPXE_Server_IP%.*}.181
    Range2=${iPXE_Server_IP%.*}.200
    Broadcast=${iPXE_Server_IP%.*}.255

    # Create DHCP configuration
    mkdir -p /etc/dhcp
    cat > /etc/dhcp/dhcpd.conf << EOF
ddns-update-style none;
option domain-name "example.org";
option domain-name-servers 8.8.8.8;
default-lease-time 600;
max-lease-time 7200;
log-facility local7;

subnet $Subnet netmask $Netmask {
  range $Range1 $Range2;
  option routers $GatewayIP;
  option broadcast-address $Broadcast;
  next-server $iPXE_Server_IP;
  filename = "pxelinux.0";
}

EOF

    # Create PXE by_mac template 
    mkdir -p /var/tftpboot/pxelinux.cfg
    cat > /var/tftpboot/pxelinux.cfg/by_mac.tpl << EOF
timeout 5
default iPXE
LABEL iPXE
KERNEL ipxe.krn
APPEND dhcp && chain http://iPXE_Server_IP/ipxe/InstallationHostname.ipxe
EOF

    # Create iPXE template
    mkdir -p /var/www/html/ipxe
    cat > /var/www/html/ipxe/boot.ipxe.tpl.coreos << EOF
#!ipxe

set base-url http://${iPXE_Server_IP}/images/coreos/amd64-usr/${CoreOSInstallationVersion}
kernel \${base-url}/vmlinuz cloud-config-url=http://${iPXE_Server_IP}/cloud-configs/ipxe_stage/InstallationHostname-ipxe-cloud-config.yml coreos.autologin
initrd \${base-url}/cpio.gz
boot
EOF

    cat > /var/www/html/ipxe/boot.ipxe.tpl.centos << EOF
#!ipxe

set base-url http://${iPXE_Server_IP}/repo/centos/${CentOSInstallationVersion}/os/x86_64
kernel \${base-url}/images/pxeboot/vmlinuz initrd=initrd.img repo=\${base} ks=http://${iPXE_Server_IP}/ks/InstallationHostname.cfg
initrd \${base-url}/images/pxeboot/initrd.img
boot
EOF

    cp -f systemd-conf/* /etc/systemd/system
    systemctl daemon-reload
    for i in nfs-server nginx tftp; do
        systemctl enable $i
        systemctl restart $i
    done

    rsync -avz --delete var/www/html/bin/ /var/www/html/bin/
    rsync -avz --delete var/www/html/cloud-configs/ /var/www/html/cloud-configs/
    rsync -avz --delete var/www/html/bin/ /var/www/html/bin/
    rsync -avz --delete var/www/html/scripts/ /var/www/html/scripts/
    rsync -avz --delete var/www/html/special_case/ /var/www/html/special_case/
    rsync -avz var/www/html/ks/ /var/www/html/ks/
    rsync -avz var/www/html/soft/ /var/www/html/soft/
    rsync -avz var/tftpboot/ /var/tftpboot/

    WebDir=/var/www/html
    declare -A dic
    dic=([ethX]="$ethX" [K8SVersion]="$K8SVersion" [iPXE_Server_IP]="$iPXE_Server_IP" [GatewayIP]="$GatewayIP" \
        [CoreOSInstallationVersion]="$CoreOSInstallationVersion" [CentOSInstallationVersion]="$CentOSInstallationVersion")
    for i in `echo ${!dic[*]}`; do
        for j in /etc/systemd/system/dhcp.service ${WebDir}/{bin,scripts,cloud-configs/template,ks}/* /var/tftpboot/pxelinux.cfg/by_mac.tpl; do
            sed -i "s/$i/${dic["$i"]}/g" $j
        done
    done

    # gather kubernetes manifests
    dir=var/www/html/k8s
    repositoies=(https://github.com/jaohaohsuan/heketi-kubernetes-deploy,heketi-kubernetes-deploy)

    OrigIFS=$IFS
    mkdir -p /var/www/html/k8s
    rm -rfv /var/www/html/k8s/manifests/
    for i in $repositoies; do
      IFS=","; set $i;
      local url=$1
      local repo=${dir}/$2
      if [ -d "${repo}/.git" ]; then
        cd $repo
        git checkout master
        git pull --tags
      else
        git clone $url $repo
        cd $repo
      fi
      git checkout tags/v$K8SVersion
      cd $PrepareDir
      rsync -avz --exclude='.git' ${repo}/manifests/ /var/www/html/k8s/manifests/
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

if [ "$DeployCoreOS" == "yes" ]; then
    CoreOSEnv
fi

if [ "$DeployCentOS" == "yes" ]; then
    CentOSEnv
fi

# Install python yaml module
if ! dpkg -l | grep -q "python3-pip"; then
    apt-get install -y python3-pip
    pip3 install pyyaml
fi

# Download pxelinux.0
wget -c -P /root https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz
cd /root
tar xzvf syslinux-6.03.tar.gz
mkdir -p /var/tftpboot
cp syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 /var/tftpboot
cp syslinux-6.03/bios/core/pxelinux.0 /var/tftpboot
cd $PrepareDir

# Add docker repository and install docker
if ! apt-cache policy | grep -q "apt.dockerproject.org"; then
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" >> /etc/apt/sources.list
fi
apt-key update
apt-get update
apt-get install -y docker-engine

# pull ipxe environment service images
docker pull networkboot/dhcpd
docker pull nginx:stable-alpine
docker pull cpuguy83/nfs-server
docker pull pghalliday/tftp


# Download ipxe.iso to get ipxe.krn
wget -c -P /root http://boot.ipxe.org/ipxe.iso
mount /root/ipxe.iso /mnt
cp -f /mnt/ipxe.krn /var/tftpboot
umount /mnt

# build kubeadm
cd kubeadm
`pwd`/build $K8SVersion
cd $PrepareDir

# update k8s version
set -x
sed -i 's/\(hyperkube-amd64:\|kubeadm:\)v[0-9]\+\.[0-9]\+\.[0-9]\+/\1v'$K8SVersion'/g' prod-images
set +x

# pull and tar image
if [ "$IsChina" == "no" ]; then
    imageList="./prod-images"
elif [ "$IsChina" == "yes" ]; then
    cp -f prod-images{,.for_china}
    sed -i -e 's#\(gcr.*\)/\(.*\):\(.*\)#henryrao/\2:\3#g' -e 's#\(quay.*\)/\(.*\):\(.*\)#henryrao/\2:\3#g' prod-images.for_china
    imageList="./prod-images.for_china"
fi
mkdir -p /var/www/html/images/docker
true > /var/www/html/images/docker-list
while read -r line
do
    img="$line"
    docker pull $img
    if [ "$IsChina" == "yes" ]; then
        img=`grep ${img##*/} ./prod-images`
        docker tag $line $img
    fi
    tar_filename=`echo ${img##*/} | tr ':' '_'`.tar
    echo "Saving $img to $tar_filename"
    docker save $img > /var/www/html/images/docker/$tar_filename
    echo "$tar_filename" >> /var/www/html/images/docker-list
done < $imageList

# Download ActivePython
wget -c -P var/www/html/soft http://downloads.activestate.com/ActivePython/releases/2.7.13.2713/ActivePython-2.7.13.2713-linux-x86_64-glibc-2.3.6-401785.tar.gz

UpdateConf
