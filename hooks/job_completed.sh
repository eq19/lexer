#!/usr/bin/env bash
# Structure: Cell Types – Modulo 6

hr='------------------------------------------------------------------------------------'

echo -e "\n$hr\nFinal Space\n$hr"
df -h

if [ -d /mnt/disks/platform/usr/local/sbin ]; then

  echo -e "\n$hr\nDocker images\n$hr"
  /mnt/disks/platform/usr/bin/docker image ls

  echo -e "\n$hr\nFinal Network\n$hr"
  /mnt/disks/platform/usr/bin/docker network inspect bridge

fi

echo -e "\njob completed"
