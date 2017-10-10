#!/usr/bin/env bash

set -e

[[ -f ./vars.env ]] && . ./vars.env

: ${KUBE_API_PUBLIC:-https://kube.valuphone.com:6443}
: ${KUBE_API_PRIVATE:-https://kubernetes.default}
: ${PRIVATE_CLUSTER_CNAME:-cluster.local.valuphone.com}

: ${CALICO_CNI_LOG_LEVEL:-info}

: ${ETCD_CERTS_PATH:=../pre-provisions/etcd3-ssl}

PRIVATE_IPV4S:=$(dig +short $PRIVATE_CLUSTER_CNAME | while read -r line; do echo https://$line:2379; done | xargs | tr ' ' ',')


cat | kubectl create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: calico-etcd-secrets
  namespace: kube-system
type: Opaque
data:
  ca.pem: $(base64 $ETCD_CERTS_PATH/ca.pem)
  etcd-key.pem: $(base64 $ETCD_CERTS_PATH/etcd-key.pem)
  etcd.pem: $(base64 $ETCD_CERTS_PATH/etcd.pem)
EOF

cat | kubectl create -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: calico-config
  namespace: kube-system
data:
  # Configure this with the location of your etcd cluster.
  etcd_endpoints: "$PRIVATE_IPV4S"

  # Configure the Calico backend to use.
  calico_backend: "bird"

  # The CNI network configuration to install on each node.
  cni_network_config: |-
    {
        "name": "k8s-pod-network",
        "cniVersion": "0.1.0",
        "type": "calico",
        "etcd_endpoints": "$PRIVATE_IPV4S",
        "etcd_key_file": "/etc/ssl/etcd/etcd-key.pem",
        "etcd_cert_file": "/etc/ssl/etcd/etcd.pem",
        "etcd_ca_cert_file": "/etc/ssl/etcd/ca.pem",
        "log_level": "${CALICO_CNI_LOG_LEVEL,,}",
        "mtu": 1500,
        "kubernetes": {
            "kubeconfig": "/etc/kubernetes/kube-config.yaml"
        },
        "ipam": {
            "type": "calico-ipam"
        },
        "policy": {
            "type": "k8s",
            "k8s_api_root": "$KUBE_API_PUBLIC"
        }
    }
  k8s_api: $KUBE_API_PRIVATE
  # If you're using TLS enabled etcd uncomment the following.
  # You must also populate the Secret below with these files.
  etcd_ca: "/calico-secrets/ca.pem"   # "/calico-secrets/etcd-ca"
  etcd_cert: "/calico-secrets/etcd.pem" # "/calico-secrets/etcd-cert"
  etcd_key: "/calico-secrets/etcd-key.pem"  # "/calico-secrets/etcd-key"
EOF

kubectl apply -f assets/components/calico/{.,calico-node,calico-policy-controller}
