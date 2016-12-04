#!/bin/bash

apt-get update
apt-get install -y haproxy

tee > /etc/haproxy/haproxy.cfg <<'EOF'
global
    daemon
    group haproxy
    user haproxy
    maxconn 2048

    chroot      /var/lib/haproxy

    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private
    ssl-default-bind-options no-sslv3

    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s


defaults
    timeout     connect     5s
    timeout     client      600s
    timeout     server      600s

    option      dontlognull
    option      redispatch
    option      tcplog


frontend kubeapi
    bind *:6443
    mode tcp

    default_backend         kubeapi


backend kubeapi
    mode tcp
    balance roundrobin
    option ssl-hello-chk
    server saturn           10.31.4.134:16443 check
    server jupiter          10.31.4.131:16443 check
    server pluto            10.31.4.132:16443 check
EOF

systemctl enable haproxy
systemctl restart haproxy
systemctl status haproxy -l

sleep 3
curl -k https://0.0.0.0:6443
