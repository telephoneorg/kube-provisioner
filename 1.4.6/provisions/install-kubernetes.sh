#!/bin/bash

set -e

KUBERNETES_VERSION=1.4.6
KUBERNETES_CONFIG_PATH=/etc/kubernetes

KUBE_PACKAGE="https://github.com/kubernetes/kubernetes/releases/download/v${KUBERNETES_VERSION}/kubernetes.tar.gz"
HYPERKUBE_IMAGE="gcr.io/google_containers/hyperkube:v${KUBERNETES_VERSION}"

apt-get update
apt-get install socat -y

for bin in kubectl kubelet hyperkube; do
    curl -sSL -o /usr/bin/$bin https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/$bin
    chmod +x /usr/bin/$bin
done

mkdir -p /etc/kubernetes/{ssl,manifests,addons}
mkdir -p /var/lib/kubelet
mkdir -p ~/.kube

tee /etc/kubernetes/kube-config.yaml <<'EOF'
apiVersion: v1
kind: Config
clusters:
- name: local
  cluster:
    server: https://kube.valuphone.com:6443
    certificate-authority: /etc/kubernetes/ssl/ca.pem
users:
- name: kubelet
  user:
    client-certificate: /etc/kubernetes/ssl/kubernetes.pem
    client-key: /etc/kubernetes/ssl/kubernetes-key.pem
contexts:
- context:
    cluster: local
    user: kubelet
  name: kubelet-context
current-context: kubelet-context
EOF

ln -sf /etc/kubernetes/kube-config.yaml ~/.kube/config

tee /etc/systemd/system/kubelet.service <<'EOF'
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
Requires=setup-network-environment.service
Requires=etcd.service
Requires=docker.service
Requires=calico-node.service
After=setup-network-environment.service
After=etcd.service
After=docker.service
After=calico-node.service

[Service]
WorkingDirectory=/var/lib/kubelet
EnvironmentFile=/run/network-environment
ExecStart=/usr/bin/kubelet \
        --kubeconfig=/etc/kubernetes/kube-config.yaml \
        --network-plugin=cni \
        --cni-bin-dir=/opt/cni/bin \
        --cni-conf-dir=/etc/cni/net.d \
        --feature-gates=AllAlpha=true,DynamicVolumeProvisioning=true \
        --api-servers=https://saturn.valuphone.local:6443,https://jupiter.valuphone.local:6443,https://pluto.valuphone.local:6443 \
        --tls-cert-file=/etc/kubernetes/ssl/kubernetes.pem \
        --tls-private-key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
        --register-node=true \
        --allow-privileged=true \
        --pod-manifest-path=/etc/kubernetes/manifests \
        --logtostderr=true \
        --cluster-dns=172.17.100.10 \
        --cluster-domain=cluster.local \
        --v=1

Restart=on-failure
RestartSec=10

LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

systemctl enable kubelet
systemctl start kubelet
systemctl status kubelet -l
