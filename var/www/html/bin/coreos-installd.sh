#!/bin/bash

PATH=$PATH:/opt/bin

set -e

# Create necessary directory
mkdir -p /opt/bin /opt/cni/bin /etc/cni/net.d /root/images/docker

# Download docker necessary images
for TAR in `curl http://iPXE_Server_IP/images/docker-list`; do
  wget -N -P /root/images/docker http://iPXE_Server_IP/images/docker/$TAR
  docker load -i /root/images/docker/$TAR
done

# Install python 2.7.10.12 on CoreOS
cd /opt
wget http://iPXE_Server_IP/soft/ActivePython-2.7.10.12-linux-x86_64.tar.gz
tar xzvf ActivePython-2.7.10.12-linux-x86_64.tar.gz
cd ActivePython-2.7.10.12-linux-x86_64 && ./install.sh -I /opt/python-2.7.10.12/
ln -sf /opt/python-2.7.10.12/bin/easy_install /opt/bin/easy_install
ln -sf /opt/python-2.7.10.12/bin/pip /opt/bin/pip
ln -sf /opt/python-2.7.10.12/bin/python /opt/bin/python
ln -sf /opt/python-2.7.10.12/bin/virtualenv /opt/bin/virtualenv
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

# Install bootkube
#wget -N -P /opt/bin http://iPXE_Server_IP/soft/bootkube
#chmod +x /opt/bin/bootkube

# Fetch bootkube asset
#wget -N -P /root http://iPXE_Server_IP/k8s/asset.tar

# Install kubectl on CoreOS
docker run --rm  -v /opt/bin:/tmp/bin gcr.io/google_containers/hyperkube-amd64:vK8SVersion /bin/sh -c "cp /hyperkube /tmp/bin" && ln -s /opt/bin/hyperkube /opt/bin/kubectl

# Download bash completion
mkdir -p /root/downloads
wget -N -P /root/downloads http://iPXE_Server_IP/soft/bash-completion.tgz
tar zxvf /root/downloads/bash-completion.tgz -C /var

# Touch file
touch /.check_coreos-installd.service
