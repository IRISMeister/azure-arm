#!/bin/bash

find_user_disks() {
    # is it safe to assume Host, Channel is always 3:0 ?-> No
    # There really is no clean way to tell it.
    # https://docs.microsoft.com/ja-jp/azure/virtual-machines/linux/attach-disk-portal#find-the-disk
    result=$(lsblk -o NAME,HCTL | grep -i "sd" | grep "[3-9]:0" | awk '{print $1}' )
    echo $result
}

# should find 3 disks
DISKS=$(find_user_disks)

for DISK in ${DISKS};
do
    echo "mkfs $DISK"
    mkfs -t xfs /dev/$DISK
done

IRISROOT=/iris
mkdir ${IRISROOT}
mkdir ${IRISROOT}/db
mkdir ${IRISROOT}/wij
mkdir ${IRISROOT}/journal1
mkdir ${IRISROOT}/journal2

# need a way to match which device is for what. Probably by using LUN.
ARRAY=(${DISKS})
MOUNT_OPTIONS=defaults,nofail
read UUID FS_TYPE < <(blkid -u filesystem /dev/${ARRAY[0]} |awk -F "[= ]" '{print $3" "$5}'|tr -d "\"")
LINE="UUID=${UUID}\t${IRISROOT}/wij\t${FS_TYPE}\t${MOUNT_OPTIONS}\t0 2"; echo -e "${LINE}" >> /etc/fstab

read UUID FS_TYPE < <(blkid -u filesystem /dev/${ARRAY[1]} |awk -F "[= ]" '{print $3" "$5}'|tr -d "\"")
LINE="UUID=${UUID}\t${IRISROOT}/journal1\t${FS_TYPE}\t${MOUNT_OPTIONS}\t0 2"; echo -e "${LINE}" >> /etc/fstab

read UUID FS_TYPE < <(blkid -u filesystem /dev/${ARRAY[2]} |awk -F "[= ]" '{print $3" "$5}'|tr -d "\"")
LINE="UUID=${UUID}\t${IRISROOT}/db\t${FS_TYPE}\t${MOUNT_OPTIONS}\t0 2"; echo -e "${LINE}" >> /etc/fstab

mount -a

