#!/bin/bash

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

systemctl daemon-reload
systemctl restart kubelet
systemctl status kubelet -l

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
