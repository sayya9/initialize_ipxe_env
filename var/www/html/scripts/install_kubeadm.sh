# Install kubeadm necessary bins
# TODO://henryrao should change to ENV
docker run --rm -v /opt:/opt henryrao/kubeadm:vK8SVersion sh -c "cp -u -r /out/* /opt/"
