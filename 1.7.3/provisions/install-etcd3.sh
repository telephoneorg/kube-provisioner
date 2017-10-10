#!/usr/bin/env bash

set -e

[[ -f ./vars.env ]] && . ./vars.env

: ${ETCD_VERSION:=3.0.17}

DOWNLOAD_URL=https://github.com/coreos/etcd/releases/download


tmp_dir=$(mktemp -d)
pushd $tmp_dir
    curl -LO https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz
    tar xzvf etcd-v${ETCD_VERSION}-linux-amd64.tar.gz -C . --strip-components=1
    mv etcdctl /usr/bin
    popd && rm -rf $tmp_dir


tee /etc/etcd/etcd.conf <<EOF
#[etcdctl]
ETCDCTL_ENDPOINT=https://localhost:2379
ETCDCTL_CERT_FILE=/etc/ssl/etcd/etcd.pem
ETCDCTL_KEY_FILE=/etc/ssl/etcd/etcd-key.pem
ETCDCTL_CA_FILE=/etc/ssl/etcd/ca.pem

#[etcdctlv3]
ETCDCTL_API=3
ETCDCTL_ENDPOINTS=https://localhost:2379
ETCDCTL_CACERT=/etc/ssl/etcd/ca.pem
ETCDCTL_CERT=/etc/ssl/etcd/etcd.pem
ETCDCTL_KEY=/etc/ssl/etcd/etcd-key.pem
EOF


if ! grep -q etcd ~/.bashrc; then
    tee -a ~/.bashrc <<'EOF'

if [ -f /etc/etcd/etcd.conf ]; then
    export $(cat /etc/etcd/etcd.conf | grep -v ^# | grep ^ETCDCTL | xargs)
fi
EOF
    . ~/.bashrc
fi
