#!/bin/bash

set -e

# Add the path of habitat to PATH
PATH=$PATH:/opt/sd/bin

# Install kmod
if ! [ -e /bin/kmod ]; then
  hab pkg install core/kmod
  hab pkg binlink core/kmod kmod
  ln -sf kmod /bin/lsmod 
  ln -sf kmod /bin/modprobe
fi

# Install iptables which is needed for dockerd
if ! [ -e /bin/iptables ]; then
  hab pkg install core/iptables
  hab pkg binlink core/iptables iptables

  # Load ip_tables
  modprobe ip_tables
fi

if ! [ -e /bin/docker ]; then
  # Install docker and symlink
  hab pkg install core/docker
  hab pkg binlink core/docker docker
  hab pkg binlink core/docker dockerd
  hab pkg binlink core/docker docker-containerd
  hab pkg binlink core/docker docker-init
  hab pkg binlink core/docker docker-runc
  hab pkg binlink core/docker docker-containerd-shim
  hab pkg binlink core/docker docker-containerd-ctr
  hab pkg binlink core/docker docker-proxy 
fi

# Mount cgroup
mkdir -p /cgroup/devices
mount -t cgroup -o devices devices /cgroup/devices

# Start dockerd
dockerd &
