#!/bin/bash

apt-get install -y aufs-tools ebtables bridge-utils
curl -fsSL https://get.docker.com/ | sh

tee /etc/docker/daemon.json <<'EOF'
{
    "log-driver": "journald",
    "log-level": "warn",
    "selinux-enabled": false,
    "iptables": false,
    "ip-masq": false
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

tee /etc/systemd/system/docker.service.d/50-before-deps.conf <<'EOF'
[Unit]
Before=calico-node.service
Before=kubelet.service
EOF

systemctl daemon-reload

iptables -F
iptables -t nat -F

systemctl enable docker
systemctl restart docker
systemctl status docker -l
