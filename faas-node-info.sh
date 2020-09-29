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
NODE_INFO_FILE=/local/${NODE_NAME}.info

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
echo "NodeName=$NODE_NAME" > ${NODE_INFO_FILE}
echo "IP=$NODE_PUBLIC_IP" >> ${NODE_INFO_FILE}

if [ "$NODE_TYPE" == "Master" ]; then
    # Handle FaaS master node.
    echo "CPU=16" >> ${NODE_INFO_FILE}
else
    # Handle FaaS worker nodes.
    TOTAL_VF=$(sudo ${DEV_BIND_TOOL} --status | grep 'Virtual Function' | wc -l)
    echo "CPU=$TOTAL_VF" >> ${NODE_INFO_FILE}

    DEV_BIND_TOOL="${DPDK_DIR}/usertools/dpdk-devbind.py"
    sudo ${DEV_BIND_TOOL} --status | grep 'Virtual Function' | cut -d ' ' -f 1 >> ${NODE_INFO_FILE}
fi
