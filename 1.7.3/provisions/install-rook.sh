#!/usr/bin/env bash

set -e

[[ -f ./vars.env ]] && . ./vars.env

# helm repo add rook-master http://charts.rook.io/master

: ${ROOK_RELEASE:=alpha}
: ${ROOK_NAMESPACE:=rook}
: ${ROOK_RBAC:=false}
: ${ROOK_REPLICAS:=2}


echo "Installing helm ..."
curl -sSL https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
helm init


echo "Installing rook ..."
helm repo add rook-$ROOK_RELEASE http://charts.rook.io/$ROOK_RELEASE

helm install --name rook --namespace $ROOK_NAMESPACE --set rbacEnable=$ROOK_RBAC --wait --timeout 600 rook-$ROOK_RELEASE/rook

kubectl label nodes storage-node=true --all

kubectl create -f <(sed "s/__RELEASE__/$ROOK_RELEASE/" assets/components/rook/rook-cluster.yaml)

kubectl create -f <(sed "s/__REPLICAS__/$ROOK_REPLICAS/" assets/components/rookH/rook-storagepool.yaml)

kubectl create -f assets/components/rook/rook-tools.yaml


echo "Installing object storage..."
kubectl exec rook-tools -n rook -- rookctl object create
kubectl exec rook-tools -n rook -- rookctl object user create rook-user "A rook rgw user"

echo "Make note of the environment variables here ..."
kubectl exec rook-tools -n rook -- rookctl object connection rook-user --format env-var


# get a shell on the rook-tools pod:
#   kubectl exec -ti rook-tools -n rook bash
#   rookctl object create
#   rookctl object user create rook-user "A rook rgw user"
#
# To get the s3 environment variables, run the following:
# ref: https://github.com/rook/rook/blob/master/Documentation/client.md#object-storage
#   rookctl object connection rook-user --format env-var

# export AWS_HOST=rook-ceph-rgw
# export AWS_ENDPOINT=172.17.100.215:53390
# export AWS_ACCESS_KEY_ID=66PH4YT0D5WUMBGYO1Q6
# export AWS_SECRET_ACCESS_KEY=cZbchMBXiH885kF19UZEqgtyQHP0vPxyi66BBFSP

# [?(@.type=="Ready")].address
# kubectl get po -n rook -l app=rook -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}'
