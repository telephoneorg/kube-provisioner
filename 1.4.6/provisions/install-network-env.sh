#!/bin/bash

NETWORK_ENV_VERSION=1.0.0

curl -L -o /usr/local/bin/setup-network-environment \
    https://github.com/kelseyhightower/setup-network-environment/releases/download/v${NETWORK_ENV_VERSION}/setup-network-environment

chmod +x /usr/local/bin/setup-network-environment
tee /etc/systemd/system/setup-network-environment.service <<'EOF'
[Unit]
Description=Setup Network Environment
Documentation=https://github.com/kelseyhightower/setup-network-environment
Requires=network-online.target
After=network-online.target
Before=docker.service
Before=kubelet.service
Before=calico-node.service

[Service]
ExecStart=/usr/local/bin/setup-network-environment \
    -o /run/network-environment

RemainAfterExit=yes
Type=oneshot
EOF

systemctl daemon-reload
systemctl start setup-network-environment
systemctl status setup-network-environment -l
