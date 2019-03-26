#!/bin/bash

#=======================#
# Mount Jenkins volume  #
#=======================#
DEVICE_1=/dev/$(lsblk -n | awk '$NF != "/" {print $1}'|tail -1)
FS_TYPE_1=$(file -s $DEVICE_1 | awk '{print $2}')
MOUNT_POINT_1=/var/lib/jenkins

# If no FS, then this output contains "data"
if [ "$FS_TYPE_1" = "data" ]
then
    echo "Creating file system on $DEVICE_1"
    mkfs -t ext4 $DEVICE_1
fi

mkdir $MOUNT_POINT_1
mount $DEVICE_1 $MOUNT_POINT_1

#=======================#
# Mount Docker volume   #
#=======================#
DEVICE_2=/dev/$(lsblk -n | awk '$NF != "/" {print $1}'|tail -1)
FS_TYPE_2=$(file -s $DEVICE_2 | awk '{print $2}')
MOUNT_POINT_2=/var/lib/docker

# If no FS, then this output contains "data"
if [ "$FS_TYPE_2" = "data" ]
then
    echo "Creating file system on $DEVICE_2"
    mkfs -t ext4 $DEVICE_2
fi

mkdir $MOUNT_POINT_2
mount $DEVICE_2 $MOUNT_POINT_2