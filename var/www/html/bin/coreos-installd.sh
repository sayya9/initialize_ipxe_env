#!/bin/bash

PATH=$PATH:/opt/bin

set -e

# Create necessary directory
mkdir -p /opt/bin /etc/cni/net.d /root/images/docker

# Install python 2.7.10.12 on CoreOS
cd /opt
wget -q http://iPXE_Server_IP/soft/ActivePython-2.7.10.12-linux-x86_64.tar.gz
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

# Install kubeadm necessary bins
# TODO://henryrao should change to ENV
docker run --rm -v /opt:/opt henryrao/kubeadm:vK8SVersion sh -c "cp -u -r /out/* /opt/"

# Install bootkube
#wget -q -N -P /opt/bin http://iPXE_Server_IP/soft/bootkube
#chmod +x /opt/bin/bootkube

# Fetch bootkube asset
#wget -q -N -P /root http://iPXE_Server_IP/k8s/asset.tar

# Fetch rkt images
#rkt fetch --insecure-options=all http://iPXE_Server_IP/images/rkt/hyperkube/vK8SVersion_coreos.0/hyperkube.aci

# Install kubectl on CoreOS
#docker run --rm  -v /opt/bin:/tmp/bin gcr.io/google_containers/hyperkube-amd64:vK8SVersion /bin/sh -c "cp /hyperkube /tmp/bin" && ln -s /opt/bin/hyperkube /opt/bin/kubectl

# Download bash completion
mkdir -p /root/downloads
wget -q -N -P /root/downloads http://iPXE_Server_IP/soft/bash-completion.tgz
tar zxvf /root/downloads/bash-completion.tgz -C /var

# Download docker necessary images
for TAR in `curl http://iPXE_Server_IP/images/docker-list`; do
  wget -q -N -P /root/images/docker http://iPXE_Server_IP/images/docker/$TAR
  docker load -i /root/images/docker/$TAR
done

# Touch file
touch /.check_coreos-installd.service
