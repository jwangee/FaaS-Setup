#!/bin/bash
#
# Collect information needed by the FaaS-NFV Controller.
# FaaS master node: nodeName, public IP, CPU
# FaaS worker nodes: nodeName, public IP, CPU, PCIe devices, switchPort

set -e

usage() {
    echo "faas-node-info.sh -t <NODE_TYPE> -n <NODE_NAME>"
}

NODE_TYPE=""
NODE_NAME=""
NODE_PUBLIC_IP=$(ip route get $(ip route show 0.0.0.0/0 | grep -oP 'via \K\S+') | grep -oP 'src \K\S+')

DPDK_VERSION="dpdk-17.11"
DPDK_DIR="/local/dpdk-17.11"
DEV_BIND_TOOL="${DPDK_DIR}/usertools/dpdk-devbind.py"

while getopts "h?t:n:" opt; do
    case "${opt}" in
        h|\?)
            usage
            exit 0
            ;;
        t)
            NODE_TYPE=${OPTARG}
            ;;
        n)
            NODE_NAME=${OPTARG}
            ;;
    esac
done

if [ -z ${NODE_TYPE} ]; then
    usage
    exit -1
fi
if [ -z ${NODE_NAME} ]; then
    usage
    exit -1
fi

# Main
echo "NodeName=$NODE_NAME" > ${NODE_NAME}.info
echo "IP=$NODE_PUBLIC_IP" >> ${NODE_NAME}.info

if [ "$NODE_TYPE" == "Master" ];
then
    # Handle FaaS master node.
    echo "CPU=16" >> ${NODE_NAME}.info
else
    # Handle FaaS worker nodes.
    TOTAL_VF=$(sudo ${DEV_BIND_TOOL} --status | grep 'Virtual Function' | wc -l)
    echo "CPU=$TOTAL_VF" >> ${NODE_NAME}.info

    DEV_BIND_TOOL="${DPDK_DIR}/usertools/dpdk-devbind.py"
    sudo ${DEV_BIND_TOOL} --status | grep 'Virtual Function' | cut -d ' ' -f 1 >> ${NODE_NAME}.info
fi
