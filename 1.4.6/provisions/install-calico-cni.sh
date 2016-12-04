#!/bin/bash

set -e 

CALICO_CNI_VERSION=1.5.0

mkdir -p /opt/cni/bin

curl -sSL -o /opt/cni/bin/calico \
    https://github.com/projectcalico/calico-cni/releases/download/v${CALICO_CNI_VERSION}/calico

curl -sSL -o /opt/cni/bin/calico-ipam \
    https://github.com/projectcalico/calico-cni/releases/download/v${CALICO_CNI_VERSION}/calico-ipam

mkdir /tmp/cni
pushd $_
curl -sSL -o cni.tar.gz \
    https://github.com/containernetworking/cni/releases/download/v0.3.0/cni-v0.3.0.tgz
tar xzvf cni.tar.gz
cp loopback /opt/cni/bin/
popd && rm -rf $OLDPWD

chmod +x /opt/cni/bin/*

mkdir -p /etc/cni/net.d

tee /etc/cni/net.d/10-calico.conf <<'EOF'
{
    "name": "calico-k8s-network",
    "type": "calico",
    "etcd_endpoints": "https://saturn.valuphone.local:2379,https://jupiter.valuphone.local:2379,https://pluto.valuphone.local:2379",
    "etcd_ca_cert_file": "/etc/ssl/etcd/ca.pem",
    "etcd_cert_file": "/etc/ssl/etcd/etcd.pem",
    "etcd_key_file": "/etc/ssl/etcd/etcd-key.pem",
    "log_level": "DEBUG",
    "kubernetes": {
        "kubeconfig": "/etc/kubernetes/kube-config.yaml"
    },
    "ipam": {
        "type": "calico-ipam"
    },
    "policy": {
        "type": "k8s",
        "k8s_api_root": "https://kube.valuphone.com:6443"
    }
}
EOF
