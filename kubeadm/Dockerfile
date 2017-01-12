FROM alpine:edge

ARG cni_url=https://dl.k8s.io/network-plugins/cni-amd64-07a8a28637e97b22eb8dfe710eeae1344f69d16e.tar.gz

RUN apk --update add --virtual build-dependencies curl \
  && mkdir -p /out/cni \
  && curl -Lsk $cni_url | tar -zxC /out/cni \
  && apk del build-dependencies \
  && rm -rf /var/cache/apk/*

ADD ./kubernetes-1.5.1/_output/dockerized/bin/linux/amd64/kubeadm /out/bin/kubeadm
