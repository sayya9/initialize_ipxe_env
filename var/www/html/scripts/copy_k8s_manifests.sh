# copy kubernetes manifests
mkdir -p /srv/asset
curl -Lsk http://iPXE_Server_IP/k8s/manifests.tar.gz | tar -mzxC /srv/asset
