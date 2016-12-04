#!/bin/bash

# load system secrets
kubectl create -f assets/system-secrets

# load heapster
kubectl create -f assets/extras/heapster

# load ingress controller
kubectl create -f assets/extras/nginx-ingress-controller

sleep 20

# load kube lego
kubectl create -f assets/extras/kube-lego
