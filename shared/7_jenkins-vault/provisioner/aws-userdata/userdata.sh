#!/bin/bash -x

#
# ENV VAR
#
FSTAB_FILE="/etc/fstab"

#=======================#
# Ansible pre-reqs      #
#=======================#
apt-get update
apt-get install -y python-dev python-pip libffi-dev libssl-dev libxml2-dev libxslt1-dev libjpeg8-dev zlib1g-dev python-setuptools git

#
# AWS Mount EBS volumes doc: https://docs.amazonaws.cn/en_us/AWSEC2/latest/UserGuide/ebs-using-volumes.html
#
#=======================#
# Mount Jenkins volume  #
#=======================#
DEVICE_1=/dev/$(lsblk -n | awk '$NF != "/" {print $1}'|tail -2|head -1)
echo "==========================="
echo "DEVICE_1: $DEVICE_1"
echo "==========================="
echo ""

FS_CLASS_1=$(file -s $DEVICE_1 | awk '{print $2}')
MOUNT_POINT_1=/var/lib/jenkins

# If no FS, then this output contains "data"
if [ "$FS_CLASS_1" = "data" ]
then
    echo "Creating file system on $DEVICE_1"
    mkfs -t ext4 $DEVICE_1
fi

mkdir -p $MOUNT_POINT_1
mount $DEVICE_1 $MOUNT_POINT_1

#
# Adding persistent /etc/fstab step for DEVICE_1
# UUID=aebf131c-6957-451e-8d34-ec978d9581ae  /data  xfs  defaults,nofail         0  2
# UUID=aebf131c-6957-451e-8d34-ec978d9581ae  /home  ext4 defaults,auto_da_alloc  0  2
#
UUID_1="UUID=$(blkid|grep "$DEVICE_1"|cut -d'"' -f2)"
echo "$UUID_1"
echo ""

if grep -q "$UUID_1" "$FSTAB_FILE"
    then
        echo "Entry $UUID_1 already exists in $FSTAB_FILE."
    else
        FS_TYPE_1=$(blkid|grep "$DEVICE_1"|cut -d'"' -f4)
        echo "FS_TYPE_1: $FS_TYPE_1"
        echo ""

        FS_MNTOPS_1="defaults,nofail"

        #3This field is used by dump(8)  to  determine  which  filesystems  need  to  be  dumped.
        #Defaults to zero (don't dump) if not present.
        FS_FREQ_1="0"

        # This  field  is  used  by fsck(8) to determine the order in which filesystem checks are
        # done at boot time.  The root filesystem should be specified  with  a  fs_passno  of  1.
        # Other  filesystems  should  have  a fs_passno of 2. Filesystems within a drive will be
        # checked sequentially, but filesystems on different drives will be checked at  the  same
        # time  to  utilize parallelism available in the hardware.  Defaults to zero (don't fsck)
        # if not present.
        FS_PASSNO_1="2"

        echo "/etc/fstab 1 -> $UUID_1 $MOUNT_POINT_1 $FS_TYPE_1 $FS_MNTOPS_1 $FS_FREQ_1 $FS_PASSNO_1"
        echo "$UUID_1 $MOUNT_POINT_1 $FS_TYPE_1 $FS_MNTOPS_1 $FS_FREQ_1 $FS_PASSNO_1" >> /etc/fstab
fi

#=======================#
# Mount Docker volume   #
#=======================#
DEVICE_2=/dev/$(lsblk -n | awk '$NF != "/" {print $1}'|tail -1)
echo "==========================="
echo "DEVICE_2: $DEVICE_2"
echo "==========================="
echo ""

FS_CLASS_2=$(file -s $DEVICE_2 | awk '{print $2}')
MOUNT_POINT_2=/var/lib/docker

# If no FS, then this output contains "data"
if [ "$FS_CLASS_2" = "data" ]
then
    echo "Creating file system on $DEVICE_2"
    mkfs -t ext4 $DEVICE_2
fi

mkdir -p $MOUNT_POINT_2
mount $DEVICE_2 $MOUNT_POINT_2

#
# Adding persistent /etc/fstab step for DEVICE_1
# UUID=aebf131c-6957-451e-8d34-ec978d9581ae  /data  xfs  defaults,nofail         0  2
# UUID=aebf131c-6957-451e-8d34-ec978d9581ae  /home  ext4 defaults,nofail         0  2
#
UUID_2="UUID=$(blkid|grep "$DEVICE_2"|cut -d'"' -f2)"
echo "$UUID_2"
echo ""

if grep -q "$UUID_2" "$FSTAB_FILE"
    then
        echo "Entry $UUID_2 already exists in $FSTAB_FILE."
    else
        FS_TYPE_2=$(blkid|grep "$DEVICE_2"|cut -d'"' -f4)
        echo "FS_TYPE_2: $FS_TYPE_2"
        echo ""

        FS_MNTOPS_2="defaults,nofail"

        #3This field is used by dump(8)  to  determine  which  filesystems  need  to  be  dumped.
        #Defaults to zero (don't dump) if not present.
        FS_FREQ_2="0"

        # This  field  is  used  by fsck(8) to determine the order in which filesystem checks are
        # done at boot time.  The root filesystem should be specified  with  a  fs_passno  of  1.
        # Other  filesystems  should  have  a fs_passno of 2. Filesystems within a drive will be
        # checked sequentially, but filesystems on different drives will be checked at  the  same
        # time  to  utilize parallelism available in the hardware.  Defaults to zero (don't fsck)
        # if not present.
        FS_PASSNO_2="2"

        echo "/etc/fstab 1 -> $UUID_2 $MOUNT_POINT_2 $FS_TYPE_2 $FS_MNTOPS_2 $FS_FREQ_2 $FS_PASSNO_2"
        echo "$UUID_2 $MOUNT_POINT_2 $FS_TYPE_2 $FS_MNTOPS_2 $FS_FREQ_2 $FS_PASSNO_2" >> /etc/fstab
fi


