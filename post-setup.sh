#!/bin/bash
#
# The default script for all machines in the FaaS cluster.
# All: change the ownership and the permission for /local
# FaaS workers: update CPU iso

set -e

usage() {
        echo "post-setup.sh -t <NODE_TYPE>"
}

NODE_TYPE=""
NODE_IP=""
NODE_NAME=""
GRUB_BACKUP=/etc/default/grub_backup
INSTALL_DIR=$(dirname ${0})
LOG_FILE=/local/setup.log


while getopts "h?t:i:n:" opt; do
    case "${opt}" in
        h|\?)
            usage
            exit 0
            ;;
        t)
            NODE_TYPE=${OPTARG}
            ;;
        i)
            NODE_IP=${OPTARG}
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

if [ "$NODE_TYPE" == "Master" ]; then
    # Replace the protoc-gen with the right version
    cp /local/protoc-gen-go ~/go/bin/

    echo '' >> ~/.bashrc
    echo 'export PATH="$PATH:/usr/local/go/bin"' >> ~/.bashrc
    echo 'export GOROOT=/usr/local/go' >> ~/.bashrc
    echo 'export GOPATH=$GO_PATH' >> ~/.bashrc
    echo 'export PATH="$PATH:/users/uscnsl/go/bin"' >> ~/.bashrc
    echo 'export GO11MODULE=on' >> ~/.bashrc

    echo '' >> ~/.bashrc
    echo 'alias nodes="kubectl get nodes"' >> ~/.bashrc
    echo 'alias pods="kubectl get pods -n openfaas-fn"' >> ~/.bashrc
    echo 'alias deps="kubectl get deployments -n openfaas-fn"' >> ~/.bashrc
    echo 'alias dd="kubectl delete deployments --all -n openfaas-fn"' >> ~/.bashrc
    echo 'alias logs="kubectl logs -n openfaas-fn"' >> ~/.bashrc
    source ~/.bashrc
fi
