#!/bin/bash

kubectl config set-cluster lw-east --server=https://kube.valuphone.com:6443 --certificate-authority=../ssl-gen/ca.pem --embed-certs --kubeconfig=./kube-config.yaml
kubectl config set-credentials admin --certificate-authority=../ssl-gen/ca.pem --client-key=../ssl-gen/kubernetes-key.pem --client-certificate=../ssl-gen/kubernetes.pem --embed-certs --kubeconfig=./kube-config.yaml
kubectl config set-context default --cluster=lw-east --user=admin --kubeconfig=./kube-config.yaml
kubectl config use-context default --kubeconfig=./kube-config.yaml
