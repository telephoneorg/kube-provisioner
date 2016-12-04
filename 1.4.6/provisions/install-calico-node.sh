#!/bin/bash

set -e 

curl -L -o /usr/bin/calicoctl \
    http://www.projectcalico.org/builds/calicoctl
chmod +x /usr/bin/calicoctl

mkdir -p /etc/calico
tee /etc/calico/calicoctl.cfg <<'EOF'
apiVersion: v1
kind: calicoApiConfig
metadata:
spec:
  etcdEndpoints: https://saturn.valuphone.local:2379,https://jupiter.valuphone.local:2379,https://pluto.valuphone.local:2379
  etcdCaCertFile: /etc/ssl/etcd/ca.pem
  etcdCertFile: /etc/ssl/etcd/etcd.pem
  etcdKeyfile: /etc/ssl/etcd/etcd-key.pem
EOF

tee /etc/systemd/system/calico-node.service <<'EOF'
[Unit]
Description=Calico per-node agent
Documentation=https://github.com/projectcalico/calico-docker
After=docker.service
Requires=docker.service

[Service]
User=root
EnvironmentFile=/run/network-environment
PermissionsStartOnly=true
ExecStart=/usr/bin/calicoctl node run \
    --ip=${ETH1_IPV4} \
    --init-system \
    --no-default-ippools
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /etc/systemd/system/calico-node.service.d

tee /etc/systemd/system/calico-node.service.d/40-overrides.conf <<'EOF'
[Unit]
Requires=setup-network-environment.service
Requires=etcd.service
After=setup-network-environment.service
After=etcd.service
EOF

systemctl daemon-reload
systemctl enable calico-node
systemctl start calico-node

sleep 3

calicoctl apply -f - <<'EOF'
apiVersion: v1
kind: ipPool
metadata:
  cidr: 172.17.0.0/16
spec:
  nat-outgoing: true
EOF
