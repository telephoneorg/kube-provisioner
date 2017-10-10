#!/usr/bin/env bash

set -e

[[ -f ../vars.env ]] && . ../vars.env

: ${KUBE_API_PUBLIC:-https://kube.valuphone.com:6443}
: ${KUBE_API_PRIVATE:-https://kubernetes.default}
: ${PRIVATE_CLUSTER_CNAME:-cluster.local.valuphone.com}

: ${KUBE_CLUSTER:-lw-east}
: ${KUBE_USER:-admin}
: ${KUBE_CONTEXT:-default}

: ${KUBE_CERTS_PATH:=../../pre-provisions/kube-ssl}


kubectl config set-cluster $KUBE_CLUSTER \
    --server=$KUBE_API_PUBLIC \
    --certificate-authority=$KUBE_CERTS_PATH/ca.pem \
    --embed-certs \
    --kubeconfig=../kube-config.yaml

kubectl config set-credentials $KUBE_USER \
    --certificate-authority=$KUBE_CERTS_PATH/ca.pem \
    --client-key=$KUBE_CERTS_PATH/kubernetes-key.pem \
    --client-certificate=$KUBE_CERTS_PATH/kubernetes.pem \
    --embed-certs \
    --kubeconfig=../kube-config.yaml

kubectl config set-context $KUBE_CONTEXT \
    --cluster=$KUBE_CLUSTER \
    --user=$KUBE_USER \
    --kubeconfig=../kube-config.yaml

kubectl config use-context $KUBE_CONTEXT \
    --kubeconfig=../kube-config.yaml
