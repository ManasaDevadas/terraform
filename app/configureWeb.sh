#! /bin/bash

set -x

yum update -y

MOUNT_DIR="/logdevices"
# Mount additional disk
if [[ ! -d "$MOUNT_DIR" ]]; then
	mkdir -p $MOUNT_DIR
fi
if grep -q "$MOUNT_DIR" /etc/fstab; then
        echo "WARNING: Skipping additional disk mount as it is already present in /etc/fstab"
else 
	
	pvcreate /dev/sdc
	pvcreate /dev/sdd
	vgcreate vg1 /dev/sdc /dev/sdd
	lvcreate -n lv01 -l 100%VG vg1
	mkfs.xfs /dev/vg1/lv01
	partprobe /dev/vg1/lv01
	# Add fstab entry
	UUID=$(blkid -s UUID -o value  /dev/vg1/lv01)
	echo UUID=$UUID $MOUNT_DIR xfs discard,defaults,nofail 0 2 | tee -a /etc/fstab
	mount -a
fi

systemctl stop firewalld
systemctl disable firewalld

yum install httpd -y
yum install httpd-devel -y
systemctl enable httpd
systemctl start httpd