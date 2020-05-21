#!/bin/bash

GRUB_BACKUP=/etc/default/grub_backup

if [ ! -f ${GRUB_BACKUP} ]; then
  sudo cp /etc/default/grub ${GRUB_BACKUP}
  sudo sed '/GRUB_CMDLINE_LINUX=/ s/"$/ iommu=pt intel_iommu=on"/' ${GRUB_BACKUP} | sudo tee /etc/default/grub > /dev/null
  sudo update-grub
  sudo reboot
else
  bash sr-iov.sh
  bash kub-install.sh
fi
