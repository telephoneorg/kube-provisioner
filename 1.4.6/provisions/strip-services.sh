#!/bin/bash

apt-get purge nfs-kernel-server nfs-common portmap rpcbind --auto-remove -y
apt-get purge exim4 exim4-base exim4-config exim4-daemon-light --auto-remove -y
systemctl daemon-reload
