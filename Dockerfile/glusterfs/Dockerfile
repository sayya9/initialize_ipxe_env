FROM ubuntu:xenial

ARG DEBIAN_FRONTEND=noninteractive

RUN ["/bin/bash", "-c", "mkdir -p /build/config/{etc/glusterfs,var/lib/glusterd,var/log/glusterfs}"]

RUN apt-get update && \
    apt-get install -y software-properties-common net-tools iproute && \
    add-apt-repository ppa:gluster/glusterfs-3.7 && \
    apt-get update && \
    apt-get install -y curl xfsprogs && \
    apt-get install -y glusterfs-server=3.7.18-ubuntu1~xenial1 && \
    rm -rf /var/lib/apt/lists/* && \
    cp -pr /etc/glusterfs/* /build/config/etc/glusterfs && \
    cp -pr /var/lib/glusterd/* /build/config/var/lib/glusterd && \
    cp -pr /var/log/glusterfs/* /build/config/var/log/glusterfs 2> /dev/null || true

RUN curl -Ls https://github.com/Yelp/dumb-init/releases/download/v1.1.3/dumb-init_1.1.3_amd64 > /usr/local/bin/dumb-init && \
    chmod g+x /usr/local/bin/dumb-init

ADD entrypoint.sh /build/entrypoint.sh
ADD utils.sh /build/utils.sh
ADD create_cluster.sh /build/create_cluster.sh

EXPOSE 24007 2049 6010 6011 6012 38465 38466 38468 \
       38469 49152 49153 49154 49156 49157 49158 49159 49160 49161 49162

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
