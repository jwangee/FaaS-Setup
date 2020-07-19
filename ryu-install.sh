#!/bin/bash

# Install dependencies
sudo apt update
sudo apt install git python python-pip python-scapy -y
sudo apt install gcc apt-transport-https ca-certificates libffi-dev libxml2-dev libxslt1-dev zlib1g-dev -y
sudo apt install libunwind8-dev liblzma-dev libpcap-dev libssl-dev libgflags-dev libgoogle-glog-dev libgtest-dev libgrpc++-dev libprotobuf-dev libc-ares-dev libgtest-dev protobuf-compiler-grpc -y
# The following packages are needed to run bessctl
sudo pip install protobuf grpcio grpcio-tools webob tinyrpc scapy

# Install Ryu
cd /local
git clone https://github.com/faucetsdn/ryu.git
cd ryu/
pip install .
sudo python setup.py install
