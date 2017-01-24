# Download docker necessary images
mkdir -p /root/images/docker
for TAR in `curl http://iPXE_Server_IP/images/docker-list`; do
  wget -q -N -P /root/images/docker http://iPXE_Server_IP/images/docker/$TAR
  docker load -i /root/images/docker/$TAR
done
