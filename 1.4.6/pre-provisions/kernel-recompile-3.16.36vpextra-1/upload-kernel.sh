#!/bin/bash

kernel_pkg='linux-image-3.16.36vpextra-1_3.16.36vpextra-1-1_amd64.deb'
servers=(saturn jupiter pluto)

for server in "${servers[@]}"
do
    echo "Updating $server ..."
    scp "$kernel_pkg" $server:/root/
    ssh $server "dpkg -i /root/$kernel_pkg"
    ssh $server 'reboot'
done