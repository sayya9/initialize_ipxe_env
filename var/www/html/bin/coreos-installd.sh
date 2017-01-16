PATH=$PATH:/opt/bin

# Create necessary directory
mkdir -p /opt/bin /etc/cni/net.d /root/images/docker

# Load dm_thin_pool module
modprobe dm_thin_pool

# Install python 2.7.10.12 on CoreOS
cd /opt
wget -q http://iPXE_Server_IP/soft/ActivePython-2.7.10.12-linux-x86_64.tar.gz
tar xzvf ActivePython-2.7.10.12-linux-x86_64.tar.gz 2> /dev/null
cd ActivePython-2.7.10.12-linux-x86_64 && ./install.sh -I /opt/python-2.7.10.12/
ln -sf /opt/python-2.7.10.12/bin/easy_install /opt/bin/easy_install
ln -sf /opt/python-2.7.10.12/bin/pip /opt/bin/pip
ln -sf /opt/python-2.7.10.12/bin/python /opt/bin/python
ln -sf /opt/python-2.7.10.12/bin/virtualenv /opt/bin/virtualenv
rm -rf /opt/ActivePython-2.7.10.12-linux-x86_64.tar.gz /opt/ActivePython-2.7.10.12-linux-x86_64/

# Install tmux on CoreOS
curl -o /opt/bin/tmux http://iPXE_Server_IP/soft/tmux
chmod +x /opt/bin/tmux

# Download vim of newer version
curl -Lsk http://iPXE_Server_IP/soft/vim.tgz | tar -zxC /opt
curl -Lsk http://iPXE_Server_IP/soft/vim-runtime.tar.gz | tar -zxC /opt/vim
# curl -o /opt/vim/share/defaults.vim http://iPXE_Server_IP/misc/vimrc.txt

# Fetch rkt images
#rkt fetch --insecure-options=all http://iPXE_Server_IP/images/rkt/hyperkube/vK8SVersion_coreos.0/hyperkube.aci

# Download bash completion
mkdir -p /root/downloads
wget -q -N -P /root/downloads http://iPXE_Server_IP/soft/bash-completion.tgz
tar zxvf /root/downloads/bash-completion.tgz -C /var

# Download docker necessary images
for TAR in `curl http://iPXE_Server_IP/images/docker-list`; do
  wget -q -N -P /root/images/docker http://iPXE_Server_IP/images/docker/$TAR
  docker load -i /root/images/docker/$TAR
done

# Install kubeadm necessary bins
# TODO://henryrao should change to ENV
docker run --rm -v /opt:/opt henryrao/kubeadm:vK8SVersion sh -c "cp -u -r /out/* /opt/"

# cp kubernetes manifests
mkdir -p /srv/asset
curl -Lsk http://iPXE_Server_IP/k8s/manifests.tar.gz | tar -zxC /srv/asset

# Touch file
touch /.check_coreos-installd.service
