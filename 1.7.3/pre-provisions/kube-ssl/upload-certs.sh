#!/bin/bash

servers=(saturn jupiter pluto)
for server in "${servers[@]}"
do
    echo "Updating $server ..."
    ssh $server 'mkdir -p /etc/kubernetes/ssl'

    scp ca.pem $server:/etc/kubernetes/ssl/
    scp ca.pem $server:/etc/ssl/certs/
    scp kubernetes.pem $server:/etc/kubernetes/ssl/
    scp kubernetes-key.pem $server:/etc/kubernetes/ssl/

    ssh $server 'chmod g+r /etc/kubernetes/ssl/kubernetes-key.pem'
    ssh $server 'update-ca-certificates'
done
