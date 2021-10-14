#!/bin/bash

is_partitioned() {
    OUTPUT=$(partx -s ${1} 2>&1)
    egrep "partition table does not contains usable partitions|failed to read partition table" <<< "${OUTPUT}" >/dev/null 2>&1
    if [ ${?} -eq 0 ]; then
        return 1
    else
        return 0
    fi
}

has_filesystem() {
    DEVICE=${1}
    OUTPUT=$(file -L -s ${DEVICE})
    grep filesystem <<< "${OUTPUT}" > /dev/null 2>&1
    return ${?}
}

scan_for_new_disks() {
    # Looks for unpartitioned disks
    declare -a RET
    DEVS=($(ls -1 /dev/sd*|egrep -v "[0-9]$"))
    for DEV in "${DEVS[@]}";
    do
        # The disk will be considered a candidate for partitioning
        # and formatting if it does not have a sd?1 entry or
        # if it does have an sd?1 entry and does not contain a filesystem
        is_partitioned "${DEV}"
        if [ ${?} -eq 0 ];
        then
            has_filesystem "${DEV}1"
            if [ ${?} -ne 0 ];
            then
                RET+=" ${DEV}"
            fi
        else
            RET+=" ${DEV}"
        fi
    done
    echo "${RET}"
}

# should find 3 disks
DISKS=$(scan_for_new_disks)
echo "DISKS=${DISKS}"

for DISK in ${DISKS};
do
    echo "mkfs $DISK"
    mkfs -t xfs $DISK
done


IRISROOT=/iristest
mkdir ${IRISROOT}
mkdir ${IRISROOT}/db
mkdir ${IRISROOT}/wij
mkdir ${IRISROOT}/journal1
mkdir ${IRISROOT}/journal2

DISKS=(${DISKS})
MOUNT_OPTIONS=defaults,nofail
read UUID FS_TYPE < <(blkid -u filesystem ${DISKS[0]} |awk -F "[= ]" '{print $3" "$5}'|tr -d "\"")
LINE="UUID=${UUID}\t${IRISROOT}/wij\t${FS_TYPE}\t${MOUNT_OPTIONS}\t0 2"; echo -e "${LINE}" >> /etc/fstab

read UUID FS_TYPE < <(blkid -u filesystem ${DISKS[1]} |awk -F "[= ]" '{print $3" "$5}'|tr -d "\"")
LINE="UUID=${UUID}\t${IRISROOT}/journal1\t${FS_TYPE}\t${MOUNT_OPTIONS}\t0 2"; echo -e "${LINE}" >> /etc/fstab

read UUID FS_TYPE < <(blkid -u filesystem ${DISKS[2]} |awk -F "[= ]" '{print $3" "$5}'|tr -d "\"")
LINE="UUID=${UUID}\t${IRISROOT}/db\t${FS_TYPE}\t${MOUNT_OPTIONS}\t0 2"; echo -e "${LINE}" >> /etc/fstab

mount -a

