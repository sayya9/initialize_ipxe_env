# Download bash completion
mkdir -p /root/downloads
wget -q -N -P /root/downloads http://iPXE_Server_IP/soft/bash-completion.tgz
tar zxvf /root/downloads/bash-completion.tgz -C /var 2> /dev/null
