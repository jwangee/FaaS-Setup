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
  sudo sed '/GRUB_CMDLINE_LINUX=/ s/"$/ iommu=pt intel_iommu=on"/' ${GRUB_BACKUP} | sudo tee /etc/default/grub > /dev/null
  sudo update-grub
  # TODO: CPUISO
  sudo reboot
else
  cd $(dirname ${0})
  bash sr-iov.sh ${NODE_IP}
  bash kub-install.sh ${NODE_IP}
fi
