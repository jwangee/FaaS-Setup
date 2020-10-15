#!/bin/bash
#
# This script installs all dependencies for compiling NF containers
#

# Install dependencies
sudo apt update
sudo apt install -y make apt-transport-https ca-certificates g++ make pkg-config
sudo apt install -y git python python-pip python-scapy protobuf-compiler-grpc
sudo apt install -y libunwind8-dev liblzma-dev zlib1g-dev libpcap-dev libssl-dev libnuma-dev
sudo apt install -y libgflags-dev libgoogle-glog-dev libgraph-easy-perl libgtest-dev libgrpc++-dev libprotobuf-dev libc-ares-dev libbenchmark-dev libgtest-dev

# The following packages are required to run bessctl
sudo pip install protobuf grpcio scapy

# Install Hiredis
HIREDIS_DIR="/local/hiredis"
cd /local
if [ -d ${HIREDIS_DIR} ]; then
  echo "hiredis already exists."
else
  cd /local
  git clone http://github.com/redis/hiredis
  cd hiredis/
  make
  sudo make install
