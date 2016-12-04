#!/bin/bash

apt-get install -y apt-transport-https

curl -sSL https://download.gluster.org/pub/gluster/glusterfs/3.9/rsa.pub | apt-key add -
echo 'deb https://download.gluster.org/pub/gluster/glusterfs/LATEST/Debian/8/apt jessie main' > /etc/apt/sources.list.d/gluster.list
apt-get update

apt-get install -y glusterfs-client

# unmount the block device
sed -i '/gluster0/d' /etc/fstab
umount /data/gluster0
# wipefs the partition

# install dm_thin_pool kernel module
apt-get install -y thin-provisioning-tools
echo 'dm-thin-pool' >> /etc/modules
modprobe dm-thin-pool
