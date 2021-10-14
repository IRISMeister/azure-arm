#!/bin/bash

mkfs -t xfs /dev/sda
mkfs -t xfs /dev/sdb
mkfs -t xfs /dev/sdc

IRISROOT=/iristest
mkdir ${IRISROOT}
mkdir ${IRISROOT}/db
mkdir ${IRISROOT}/wij
mkdir ${IRISROOT}/journal1
mkdir ${IRISROOT}/journal2

MOUNT_OPTIONS=defaults,nofail
read UUID FS_TYPE < <(blkid -u filesystem /dev/sda |awk -F "[= ]" '{print $3" "$5}'|tr -d "\"")
LINE="UUID=${UUID}\t${IRISROOT}/wij\t${FS_TYPE}\t${MOUNT_OPTIONS}\t0 2"; echo -e "${LINE}" >> /etc/fstab

read UUID FS_TYPE < <(blkid -u filesystem /dev/sdb |awk -F "[= ]" '{print $3" "$5}'|tr -d "\"")
LINE="UUID=${UUID}\t${IRISROOT}/journal1\t${FS_TYPE}\t${MOUNT_OPTIONS}\t0 2"; echo -e "${LINE}" >> /etc/fstab

read UUID FS_TYPE < <(blkid -u filesystem /dev/sdc |awk -F "[= ]" '{print $3" "$5}'|tr -d "\"")
LINE="UUID=${UUID}\t${IRISROOT}/db\t${FS_TYPE}\t${MOUNT_OPTIONS}\t0 2"; echo -e "${LINE}" >> /etc/fstab

mount -a