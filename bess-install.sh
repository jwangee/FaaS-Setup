#!/bin/bash

# Install dependencies
sudo apt install make apt-transport-https ca-certificates g++ make pkg-config libunwind8-dev liblzma-dev zlib1g-dev libpcap-dev libssl-dev libnuma-dev git python python-pip python-scapy libgflags-dev libgoogle-glog-dev libgraph-easy-perl libgtest-dev libgrpc++-dev libprotobuf-dev libc-ares-dev libbenchmark-dev libgtest-dev protobuf-compiler-grpc
# The following packages are needed to run bessctl
pip install --user protobuf grpcio scapy

# Start hugepages
echo 2048 | sudo tee /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
echo 2048 | sudo tee /sys/devices/system/node/node1/hugepages/hugepages-2048kB/nr_hugepages

cd /local
git clone https://github.com/NetSys/bess.git
cd bess/
./build.py
