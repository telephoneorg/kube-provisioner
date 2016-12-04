#!/bin/bash

servers=(saturn jupiter pluto)
for server in "${servers[@]}"
do
    echo "Updating $server ..."
    ssh $server 'mkdir -p /etc/ssl/etcd'

    scp ca.pem $server:/etc/ssl/etcd/
    scp ca.pem $server:/etc/ssl/certs/
    scp etcd.pem $server:/etc/ssl/etcd/
    scp etcd-key.pem $server:/etc/ssl/etcd/

    ssh $server 'chmod g+r /etc/ssl/etcd/etcd-key.pem'
    ssh $server 'update-ca-certificates'
done


# if [ -f /etc/etcd/etcd.conf ]; then
#     export $(cat /etc/etcd/etcd.conf | grep -v ^# | xargs)
# fi
