#!/bin/bash -e

apt-get update &

# Get a new hyperctl binary from source
# referece: https://github.com/hyperhq/hyperd/blob/master/README.md#build-from-source
mkdir -p ${GOPATH}/src/github.com/hyperhq
cd ${GOPATH}/src/github.com/hyperhq
git clone https://github.com/hyperhq/hyperd.git hyperd
cd hyperd

wait
apt-get install -y automake autotools-dev libdevmapper-dev

./autogen.sh
./configure
make hyperctl

cp cmd/hyperctl/hyperctl "$SD_SOURCE_DIR/hyperctl"
cd "$SD_SOURCE_DIR"
