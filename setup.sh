#!/bin/bash
#
# The default script for all machines in the FaaS cluster.
# All: change the ownership and the permission for /local
# FaaS workers: update CPU iso

set -e

usage() {
        echo "faas-node-info.sh -t <NODE_TYPE> -i <NODE_IP>"
}

NODE_TYPE=""
NODE_IP=""
GRUB_BACKUP=/etc/default/grub_backup
INSTALL_DIR=$(dirname ${0})
LOG_FILE=/local/setup.log


while getopts "h?t:i:" opt; do
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
    esac
done

if [ -z ${NODE_TYPE} ]; then
        usage
        exit -1
fi
if [ -z ${NODE_IP} ]; then
        usage
        exit -1
fi

# Main
if [ ! -f ${GRUB_BACKUP} ]; then
    # If no backup, then backup the grub config and reboot
    sudo cp /etc/default/grub ${GRUB_BACKUP}

    if [ "$NODE_TYPE" == "Worker" ]; then
        # CPU isolation
        sudo sed '/GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ isolcpus=1-20"/' ${GRUB_BACKUP} | sudo tee /etc/default/grub > /dev/null
        sudo sed '/GRUB_CMDLINE_LINUX=/ s/"$/ iommu=pt intel_iommu=on isolcpus=1-20"/' ${GRUB_BACKUP} | sudo tee /etc/default/grub > /dev/null    
        sudo update-grub
        sudo reboot
    fi
fi


sudo apt update
sudo apt -y install htop
sudo chmod 777 $INSTALL_DIR

touch $LOG_FILE
echo "" > $LOG_FILE

if [ "$NODE_TYPE" == "Master" ]; then
    bash /local/kub-install.sh ${NODE_IP} >> $LOG_FILE
    bash /local/go-install.sh >> $LOG_FILE
    bash /local/nf-install.sh >> $LOG_FILE
elif [ "$NODE_TYPE" == "Traffic" ]; then
    bash /local/bess-install.sh ${NODE_IP} >> $LOG_FILE
    bash /local/nf-install.sh >> $LOG_FILE
elif [ "$NODE_TYPE" == "Worker" ]; then
    bash /local/kub-install.sh ${NODE_IP} >> $LOG_FILE
    bash /local/sr-iov.sh ${NODE_IP} >> $LOG_FILE
fi

echo "Done!"  >> $LOG_FILE
