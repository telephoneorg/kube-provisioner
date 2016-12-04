#!/bin/bash

THIS_LOCAL_IPV4=$(ifconfig eth1 | grep 'inet ' | awk '{print $2}' | cut -d':' -f2)
THIS_LOCAL_SHORT_HOST=$(hostname -s)
ETCD_CERT_DIR=/etc/ssl/etcd

# install etcd2
cd /tmp
curl -L  https://github.com/coreos/etcd/releases/download/v2.3.7/etcd-v2.3.7-linux-amd64.tar.gz -o etcd-v2.3.7-linux-amd64.tar.gz
tar xzvf etcd-v2.3.7-linux-amd64.tar.gz
mv etcd-v2.3.7-linux-amd64/{etcd,etcdctl} /usr/bin/
rm -rf etcd*

useradd --comment 'etcd user' --home-dir /var/lib/etcd --shell=/sbin/nologin --user-group --create-home etcd
mkdir -p /etc/etcd /var/lib/etcd/default.etcd
chown -R etcd:etcd /etc/etcd /var/lib/etcd
chmod g+r /etc/ssl/etcd/etcd-key.pem
chown -R root:etcd /etc/ssl/etcd


tee /etc/etcd/etcd.conf <<EOF
# [member]
ETCD_NAME=$THIS_LOCAL_SHORT_HOST
ETCD_DATA_DIR=/var/lib/etcd/default.etcd
ETCD_LISTEN_PEER_URLS=https://$THIS_LOCAL_IPV4:2380
ETCD_LISTEN_CLIENT_URLS=https://0.0.0.0:2379
# ETCD_WAL_DIR=
# ETCD_SNAPSHOT_COUNT=10000
# ETCD_HEARTBEAT_INTERVAL=100
# ETCD_ELECTION_TIMEOUT=1000
# ETCD_MAX_SNAPSHOTS=5
# ETCD_MAX_WALS=5
# ETCD_CORS=

# [cluster]
ETCD_INITIAL_CLUSTER_STATE=new
ETCD_INITIAL_CLUSTER_TOKEN=2ee9705598dc06df3ab66bbea3a3d440
ETCD_INITIAL_ADVERTISE_PEER_URLS=https://${THIS_LOCAL_SHORT_HOST}.valuphone.local:2380
ETCD_ADVERTISE_CLIENT_URLS=https://${THIS_LOCAL_SHORT_HOST}.valuphone.local:2379
ETCD_INITIAL_CLUSTER=saturn=https://saturn.valuphone.local:2380,jupiter=https://jupiter.valuphone.local:2380,pluto=https://pluto.valuphone.local:2380

# [proxy]
# ETCD_PROXY=off
# ETCD_PROXY_FAILURE_WAIT=5000
# ETCD_PROXY_REFRESH_INTERVAL=30000
# ETCD_PROXY_DIAL_TIMEOUT=1000
# ETCD_PROXY_WRITE_TIMEOUT=5000
# ETCD_PROXY_READ_TIMEOUT=0

# [security]
ETCD_CERT_FILE=$ETCD_CERT_DIR/etcd.pem
ETCD_KEY_FILE=$ETCD_CERT_DIR/etcd-key.pem
ETCD_TRUSTED_CA_FILE=$ETCD_CERT_DIR/ca.pem
ETCD_CLIENT_CERT_AUTH=true
ETCD_PEER_CERT_FILE=$ETCD_CERT_DIR/etcd.pem
ETCD_PEER_KEY_FILE=$ETCD_CERT_DIR/etcd-key.pem
ETCD_PEER_TRUSTED_CA_FILE=$ETCD_CERT_DIR/ca.pem
ETCD_PEER_CLIENT_CERT_AUTH=true

# [logging]
# ETCD_DEBUG=true
ETCD_LOG_PACKAGE_LEVELS=etcdserver=WARNING,security=DEBUG

# [etcdctl]
ETCDCTL_ENDPOINT=https://localhost:2379
ETCDCTL_CERT_FILE=$ETCD_CERT_DIR/etcd.pem
ETCDCTL_KEY_FILE=$ETCD_CERT_DIR/etcd-key.pem
ETCDCTL_CA_FILE=$ETCD_CERT_DIR/ca.pem
EOF

tee /etc/systemd/system/etcd.service <<EOF
[Unit]
Description=Etcd2 Server
Documentation=https://github.com/coreos/etcd
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=etcd
Group=etcd
PermissionsStartOnly=true
WorkingDirectory=/var/lib/etcd
EnvironmentFile=-/etc/etcd/etcd.conf

ExecPreStart=-/usr/bin/chown -R etcd:etcd /var/lib/etcd
ExecPreStart=-/usr/bin/chown -R root:etcd /etc/ssl/etcd
ExecPreStart=-/usr/bin/chmod g+r /etc/ssl/etcd/etcd-key.pem
ExecStart=/usr/bin/etcd
Restart=always
RestartSec=10s
LimitNOFILE=40000

[Install]
WantedBy=multi-user.target
EOF


tee -a ~/.bashrc <<'EOF'

if [ -f /etc/etcd/etcd.conf ]; then
    export $(cat /etc/etcd/etcd.conf | grep -v ^# | grep ^ETCDCTL | xargs)
fi
EOF

. ~/.bashrc

systemctl daemon-reload
systemctl enable etcd
systemctl start etcd

# after done
# sed -ir '/ETCD_INITIAL_CLUSTER_STATE/s/new/existing/' /etc/etcd/etcd.conf
# systemctl restart etcd

