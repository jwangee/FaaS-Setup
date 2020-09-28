#!/bin/bash

if [ -z "$1" ]
  then
    echo "No argurments supplied"
    exit 0
fi
NODE_IP=$1

GRUB_BACKUP=/etc/default/grub_backup

if [ ! -f ${GRUB_BACKUP} ]; then
  sudo cp /etc/default/grub ${GRUB_BACKUP}
  # CPU isolation
  sudo sed '/GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ isolcpus=1-20"/' ${GRUB_BACKUP} | sudo tee /etc/default/grub > /dev/null
  sudo sed '/GRUB_CMDLINE_LINUX=/ s/"$/ iommu=pt intel_iommu=on isolcpus=1-20"/' ${GRUB_BACKUP} | sudo tee /etc/default/grub > /dev/null
  sudo update-grub
  sudo reboot
else
  cd $(dirname ${0})
  bash sr-iov.sh ${NODE_IP}
  bash kub-install.sh ${NODE_IP}
fi
