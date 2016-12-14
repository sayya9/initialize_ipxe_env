#!/bin/bash

K8S_URL="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT_HTTPS"

if [ -e /build/utils.sh ]; then
  . /build/utils.sh
fi

function check_running_gluster {
  netstat -tan | grep 24007 | grep -v TIME_WAIT &> /dev/null
  return $?
}

function get_own_ip {
  get_peer_addresses $K8S_URL

  local found=0
  for peer_ip in "${IP_LIST[@]}"; do
    if IP_OK $peer_ip; then
      log_msg "own ip is $peer_ip"
      NODE_IP=$peer_ip;
      found=1
    fi
  done

  if [ $found -eq 0 ]; then
    log_msg "failed to get own ip"
  fi
}

function configure_network {
  #
  # Check networking available to the container, and configure accordingly
  #

  log_msg "checking $NODE_IP is available on this host"
  if IP_OK $NODE_IP; then

    # IP address provided is valid, so configure the services
    log_msg "$NODE_IP is valid"

    #log_msg "Checking glusterd is only binding to $NODE_IP"
    #if ! grep $NODE_IP /etc/glusterfs/glusterd.vol &> /dev/null; then
    #  log_msg "Updating glusterd to bind only to $NODE_IP"
    #  sed -i.bkup "/end-volume/i \ \ \ \ option transport.socket.bind-address ${NODE_IP}" /etc/glusterfs/glusterd.vol
    #else
    #  log_msg "glusterd already set to $NODE_IP"
    #fi

  else

    log_msg "IP address $NODE_IP is not available on this host. Can not start the container"
    exit 1

  fi
}

if [ ! -e /etc/glusterfs/glusterd.vol ]; then
  # this is the first run, so we need to seed the configuration
  log_msg "Seeding the configuration directories"
  cp -pr /build/config/etc/glusterfs/* /etc/glusterfs
  cp -pr /build/config/var/lib/glusterd/* /var/lib/glusterd
  cp -pr /build/config/var/log/glusterfs/* /var/log/glusterfs
fi

if ! check_running_gluster; then

  get_own_ip
  configure_network

  if empty_dir /var/lib/glusterd/peers  ; then
    log_msg "Existing peer node definitions have not been found"
    log_msg "Using the list of peers from the etcd configuration"
    log_msg "Forking the create_cluster process"
    /build/create_cluster.sh &

  else
    log_msg "Using peer definition from previous container start"
  fi

  # run gluster
  /usr/sbin/glusterd -N -p /var/run/glusterd.pid 
else
  # log: notify that another glusterservice is running in such node
  log_msg "Unable to start the container, a gluster instance is already running on this host"
fi 

