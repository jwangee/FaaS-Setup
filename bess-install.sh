#!/bin/bash

if [ -z "$1" ]
  then
    echo "No argurments supplied"
    exit 0
fi
NODE_IP_1=$1

if [ -z "$2" ]; then
  NODE_IP_2=""
else
  NODE_IP_2=$2
fi

# Install dependencies
sudo apt update
sudo apt install make apt-transport-https ca-certificates g++ make pkg-config libunwind8-dev liblzma-dev zlib1g-dev libpcap-dev libssl-dev libnuma-dev git python python-pip python-scapy libgflags-dev libgoogle-glog-dev libgraph-easy-perl libgtest-dev libgrpc++-dev libprotobuf-dev libc-ares-dev libbenchmark-dev libgtest-dev protobuf-compiler-grpc -y
# The following packages are needed to run bessctl
sudo pip install protobuf grpcio scapy

# Install BESS
BESS_DIR="/local/bess"

cd /local
if [ -d ${BESS_DIR} ]; then
  echo "BESS already exists."
else
  cd /local
  git clone https://github.com/jwangee/bess.git
  cd bess/
  sudo ./build.py
fi

# Install DPDK
DPDK_URL="https://fast.dpdk.org/rel/"
DPDK_VERSION="dpdk-19.11.3"
DPDK_DIR="/local/bess/deps/dpdk-19.11.3"
DEV_BIND_TOOL="/${DPDK_DIR}/usertools/dpdk-devbind.py"

cd /local/bess
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

INTERFACE=$(ifconfig | grep -B 1 ${NODE_IP_1} | head -1 | cut -d ':' -f 1 | cut -d ' ' -f 1)
PCI_DEVICE=$(sudo lshw -class network -businfo | grep ${INTERFACE} | cut -d ' ' -f 1 | cut -d '@' -f 2)

sudo ${DEV_BIND_TOOL} --force -u ${PCI_DEVICE}
sudo ${DEV_BIND_TOOL} -b igb_uio ${PCI_DEVICE}


INTERFACE=$(ifconfig | grep -B 1 ${NODE_IP_2} | head -1 | cut -d ':' -f 1 | cut -d ' ' -f 1)
PCI_DEVICE=$(sudo lshw -class network -businfo | grep ${INTERFACE} | cut -d ' ' -f 1 | cut -d '@' -f 2)
