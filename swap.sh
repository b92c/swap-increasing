#!/bin/bash
#About: Adds 16GB of Swap to Operational System
#Author: https://github.com/b92c

SWAP_FILE="/swapfile.swap"

#The parameter value set to "30" means that the kernel will swap when RAM reaches 70/80% capacity
SWAPPINESS="30"

function create()
{
  if grep -q "${SWAP_FILE}" /proc/swaps;then
    echo -e "Swap is already configured!";
    exit
  fi

  if [[ -e "${SWAP_FILE}" ]];then
    echo -e "Swap file already exists!";
    exit;
  fi

  PARTITION_FREE_SIZE=$(df --block-size M --output=avail / | tail -1 | sed 's/M//g');

  if [[ ${PARTITION_FREE_SIZE} -lt 17000 ]];then
    echo -e "Not enough free space on partition '/' to create swap, it needs at least 17GB!";
    exit;
  fi

  echo -e "\n=> Creating Swap file, it can take time and your computer may be slow!";
  sudo dd if=/dev/zero of=${SWAP_FILE} bs=1024 count=16M &> /dev/null
  sudo chmod 0600 ${SWAP_FILE};
  sudo mkswap ${SWAP_FILE} &> /dev/null;
  sudo chown root: ${SWAP_FILE};
  
  echo -e "\n=> Starting Swap";
  sudo swapon ${SWAP_FILE};

  echo -e "\n=> Adding to /etc/fstab"
  if grep -q "${SWAP_FILE}" /etc/fstab;then
    echo -e "Already exists!";
  else 
    sudo sh -c "echo '\n${SWAP_FILE} swap swap defaults 0 0' >> /etc/fstab"
  fi

  if ! grep -q "vm.swappiness" /etc/sysctl.conf;then
    sudo sh -c "echo 'vm.swappiness=${SWAPPINESS}' >> /etc/sysctl.conf"
    sudo sysctl -p /etc/sysctl.conf &>/dev/null
    echo -e "\n=> Added swappiness to ${SWAPPINESS}"
  fi

  echo -e "\n=> Complete! You can check the swap below";
  echo "------------------------";
  free -m
  echo "------------------------";

  echo -e "\nTo remove the swap file, run the following command: $0 remove";
}

function remove()
{
  if [[ ! -e "${SWAP_FILE}" ]];then
    echo -e "Swap file has already been removed!";
    exit;
  fi

  echo -e "\n=> Deactivating Swap, it takes time!";
  sudo swapoff ${SWAP_FILE};

  echo -e "\n=> Removing Swap file";
  sudo rm -f ${SWAP_FILE:-NULL};

  echo -e "\n=> Removing from /etc/fstab"
  if grep -q "${SWAP_FILE}" /etc/fstab;then
    sudo sed -i '/\/swapfile.swap swap swap defaults 0 0/d' /etc/fstab
  else 
    echo -e "Already been removed!";
  fi
  echo -e "\n=> Removal completed! You can check the swap below";
  echo "------------------------";
  free -m
  echo "------------------------";
}

if [[ $1 =~ "remove" ]];then
  remove;
  exit;
fi

create;