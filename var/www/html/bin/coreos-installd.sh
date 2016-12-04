#!/bin/bash

PATH=$PATH:/opt/bin

set -e

# Create necessary directory
mkdir -p /opt/bin /opt/cni/bin /etc/cni/net.d /root/images/docker /gluster

# Download docker necessary images
wget -N -P /root/images/docker http://iPXE_Server_IP/images/docker/exechealthz-amd64_1.1.tar
wget -N -P /root/images/docker http://iPXE_Server_IP/images/docker/hyperkube-amd64_v1.4.6.tar
wget -N -P /root/images/docker http://iPXE_Server_IP/images/docker/kube-discovery-amd64_1.0.tar
wget -N -P /root/images/docker http://iPXE_Server_IP/images/docker/kubedns-amd64_1.7.tar
wget -N -P /root/images/docker http://iPXE_Server_IP/images/docker/kube-dnsmasq-amd64_1.3.tar
wget -N -P /root/images/docker http://iPXE_Server_IP/images/docker/pause-amd64_3.0.tar
wget -N -P /root/images/docker http://iPXE_Server_IP/images/docker/cni_v1.4.2.tar
wget -N -P /root/images/docker http://iPXE_Server_IP/images/docker/ctl_v0.22.0.tar
wget -N -P /root/images/docker http://iPXE_Server_IP/images/docker/kube-policy-controller_v0.3.0.tar
wget -N -P /root/images/docker http://iPXE_Server_IP/images/docker/node_v0.22.0.tar

# Install python 2.7.10.12 on CoreOS
cd /opt
wget http://iPXE_Server_IP/soft/ActivePython-2.7.10.12-linux-x86_64.tar.gz
tar xzvf ActivePython-2.7.10.12-linux-x86_64.tar.gz
cd ActivePython-2.7.10.12-linux-x86_64 && ./install.sh -I /opt/python-2.7.10.12/
ln -s /opt/python-2.7.10.12/bin/easy_install /opt/bin/easy_install
ln -s /opt/python-2.7.10.12/bin/pip /opt/bin/pip
ln -s /opt/python-2.7.10.12/bin/python /opt/bin/python
ln -s /opt/python-2.7.10.12/bin/virtualenv /opt/bin/virtualenv
rm -rf /opt/ActivePython-2.7.10.12-linux-x86_64.tar.gz /opt/ActivePython-2.7.10.12-linux-x86_64/

# Install tmux on CoreOS
curl -o /opt/bin/tmux http://iPXE_Server_IP/soft/tmux
chmod +x /opt/bin/tmux

# Install kubeadm on CoreOS
wget -N -P /opt/bin http://iPXE_Server_IP/soft/kubeadm
chmod +x /opt/bin/kubeadm

# Install cni binary file
wget -N -P /opt http://iPXE_Server_IP/soft/cni-amd64-07a8a28637e97b22eb8dfe710eeae1344f69d16e.tar.gz
tar xzvf /opt/cni-amd64-07a8a28637e97b22eb8dfe710eeae1344f69d16e.tar.gz -C /opt/cni

# Import docker images
for i in `ls /root/images/docker`; do
    docker load -i /root/images/docker/$i
done

# Install kubectl on CoreOS
docker run --rm  -v /opt/bin:/tmp/bin gcr.io/google_containers/hyperkube-amd64:v1.4.6 /bin/sh -c "cp /hyperkube /tmp/bin" && ln -s /opt/bin/hyperkube /opt/bin/kubectl


# Trust trust gpg keys fetched from http
rkt trust --skip-fingerprint-review --insecure-allow-http --root http://iPXE_Server_IP/images/rkt/pubkeys.gpg

# Fetch rkt images
rkt fetch http://iPXE_Server_IP/images/rkt/hyperkube/v1.4.6_coreos.0/hyperkube.aci

# Touch file
touch /.check_coreos-installd.service
