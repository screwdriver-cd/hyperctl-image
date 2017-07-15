#!/bin/bash -e

# Get a new hyperctl binary
curl -o hyper-container.rpm https://hypercontainer-download.s3-us-west-1.amazonaws.com/0.8/centos/hyper-container-0.8.1-1.el7.centos.x86_64.rpm
rpm2cpio hyper-container.rpm | cpio -iv --to-stdout ./usr/bin/hyperctl > hyperctl
