#!/bin/bash

if [ -z "$1" ]
  then
    echo "No argurments supplied"
    exit 0
fi
NODE_IP=$1

DPDK_URL="https://fast.dpdk.org/rel/"
DPDK_VERSION="dpdk-17.11"
DPDK_DIR="/local/${DPDK_VERSION}"
DEV_BIND_TOOL="${DPDK_DIR}/usertools/dpdk-devbind.py"

sudo apt install -y libnuma-dev

if [ -d ${DPDK_DIR} ]; then
  echo "Directory ${DPDK_DIR} already exists."
else
  echo "Downloading ${DPDK_VERSION}..."
  mkdir -p ${DPDK_DIR}
  curl -s -L ${DPDK_URL}${DPDK_VERSION}.tar.gz | tar zx -C ${DPDK_DIR} --strip-components 1
fi

INTERFACE=$(ifconfig | grep -B 1 ${NODE_IP} | head -1 | cut -d ':' -f 1 | cut -d ' ' -f 1)
PCI_DEVICE=$(sudo lshw -class network -businfo | grep ${INTERFACE} | cut -d ' ' -f 1 | cut -d '@' -f 2)

echo "interface=${INTERFACE}"
echo "pcie=${PCI_DEVICE}"

echo "Set up SR-IOV for the target NIC."
echo 15 | sudo tee /sys/bus/pci/devices/${PCI_DEVICE}/sriov_numvfs

echo "Bind to driver igb_uio..."
cd ${DPDK_DIR}
make config T=x86_64-native-linuxapp-gcc
make -j
cd -
sudo modprobe uio
sudo insmod ${DPDK_DIR}/build/kmod/igb_uio.ko
sudo ${DEV_BIND_TOOL} --force -u $(${DEV_BIND_TOOL} --status | grep 'Virtual Function' | cut -d ' ' -f 1)
sudo ${DEV_BIND_TOOL} -b igb_uio $(${DEV_BIND_TOOL} --status | grep 'Virtual Function' | cut -d ' ' -f 1)

#echo "Bind to driver vfio-pci..."
#sudo modprobe vfio-pci
#sudo ${DEV_BIND_TOOL} --force -u $(${DEV_BIND_TOOL} --status | grep 'Virtual Function' | cut -d ' ' -f 1)
#sudo ${DEV_BIND_TOOL} -b vfio-pci $(${DEV_BIND_TOOL} --status | grep 'Virtual Function' | cut -d ' ' -f 1)

ip link show

echo "Configures MAC address for vf..."
sudo ip link set dev ${INTERFACE} down
sudo ip link set dev ${INTERFACE} up
# turn off rx filters
sudo ethtool -K ${INTERFACE} ntuple off
# turn off checksuming
sudo ethtool -K ${INTERFACE} rx off tx off tso off
# turn off pause frames
sudo ethtool -A ${INTERFACE} rx off tx off
# set the maximum queue size
sudo ethtool -G ${INTERFACE} rx 4096 tx 4096

sudo ip link set ${INTERFACE} vf 0 mac 00:00:00:00:00:01
sudo ip link set ${INTERFACE} vf 1 mac 00:00:00:00:00:02
sudo ip link set ${INTERFACE} vf 2 mac 00:00:00:00:00:03
sudo ip link set ${INTERFACE} vf 3 mac 00:00:00:00:00:04
sudo ip link set ${INTERFACE} vf 4 mac 00:00:00:00:00:05
sudo ip link set ${INTERFACE} vf 5 mac 00:00:00:00:00:06
sudo ip link set ${INTERFACE} vf 6 mac 00:00:00:00:00:07
sudo ip link set ${INTERFACE} vf 7 mac 00:00:00:00:00:08
sudo ip link set ${INTERFACE} vf 8 mac 00:00:00:00:00:09
sudo ip link set ${INTERFACE} vf 9 mac 00:00:00:00:00:10
sudo ip link set ${INTERFACE} vf 10 mac 00:00:00:00:00:11
sudo ip link set ${INTERFACE} vf 11 mac 00:00:00:00:00:12
sudo ip link set ${INTERFACE} vf 12 mac 00:00:00:00:00:13
sudo ip link set ${INTERFACE} vf 13 mac 00:00:00:00:00:14
sudo ip link set ${INTERFACE} vf 14 mac 00:00:00:00:00:15

echo "Disables ASLR..."
echo 0 | sudo tee /proc/sys/kernel/randomize_va_space

echo "Sets up Hugepages..."
echo 2048 | sudo tee /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
echo 2048 | sudo tee /sys/devices/system/node/node1/hugepages/hugepages-2048kB/nr_hugepages
