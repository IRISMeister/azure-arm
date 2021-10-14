#!/bin/bash

mkfs -t xfs /dev/sdc
mkfs -t xfs /dev/sdd

mkdir /iristest
mkdir /iristest/sys
mkdir /iristest/db
mkdir /iristest/jrnl
mkdir /iristest/jrnl/pri
mkdir /iristest/jrnl/alt

echo "/dev/sdc       /iristest/sys   xfs    defaults,nofail 0       2" >> /etc/fstab
echo "/dev/sdd       /iristest/db   xfs    defaults,nofail 0       2" >> /etc/fstab
echo "/dev/sde       /iristest/jrnl/pri   xfs    defaults,nofail 0       2" >> /etc/fstab

mount -a