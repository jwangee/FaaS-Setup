#!/bin/bash

if [ -z "$1" ]
  then
    echo "No argurments supplied"
    exit 0
fi
NODE_IP=$1

# Install dependencies
sudo apt update
sudo apt install make apt-transport-https ca-certificates g++ make pkg-config libunwind8-dev liblzma-dev zlib1g-dev libpcap-dev libssl-dev libnuma-dev git python python-pip python-scapy libgflags-dev libgoogle-glog-dev libgraph-easy-perl libgtest-dev libgrpc++-dev libprotobuf-dev libc-ares-dev libbenchmark-dev libgtest-dev protobuf-compiler-grpc -y
# The following packages are needed to run bessctl
sudo pip install protobuf grpcio scapy

# Start hugepages
echo 2048 | sudo tee /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
echo 2048 | sudo tee /sys/devices/system/node/node1/hugepages/hugepages-2048kB/nr_hugepages

# Install BESS
cd /local
git clone https://github.com/NetSys/bess.git
cd bess/
sudo ./build.py

# Install DPDK
cd /local
DPDK_URL="https://fast.dpdk.org/rel/"
DPDK_VERSION="dpdk-17.11"
DPDK_DIR="dpdk-17.11"
DEV_BIND_TOOL="${DPDK_DIR}/usertools/dpdk-devbind.py"

if [ -d ${DPDK_DIR} ]; then
  echo "Directory ${DPDK_DIR} already exists."
else
  echo "Downloading ${DPDK_VERSION}..."
  mkdir -p ${DPDK_DIR}
  curl -s -L ${DPDK_URL}${DPDK_VERSION}.tar.gz | tar zx -C ${DPDK_DIR} --strip-components 1
  cd ${DPDK_DIR}
  make config T=x86_64-native-linuxapp-gcc
  make -j
  cd -
fi

# Enable dpdk driver
sudo modprobe uio
sudo insmod ${DPDK_DIR}/build/kmod/igb_uio.ko

INTERFACE=$(ifconfig | grep -B 1 ${NODE_IP} | head -1 | cut -d ':' -f 1 | cut -d ' ' -f 1)
PCI_DEVICE=$(sudo lshw -class network -businfo | grep ${INTERFACE} | cut -d ' ' -f 1 | cut -d '@' -f 2)

sudo ${DEV_BIND_TOOL} --force -u ${PCI_DEVICE}
sudo ${DEV_BIND_TOOL} -b igb_uio ${PCI_DEVICE}
