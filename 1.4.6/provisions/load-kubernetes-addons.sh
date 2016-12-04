#!/bin/bash

kubectl apply -f assets/extras/namespaces
kubectl apply -f assets/extras/calico-policy-controller.yaml
kubectl apply -f assets/addons

