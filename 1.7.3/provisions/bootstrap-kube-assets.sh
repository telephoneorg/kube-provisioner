#!/usr/bin/env bash

set -e

[[ -f ./vars.env ]] && . ./vars.env

: ${THIS_NODE:-$(hostname -s)}
: ${MANIFESTS_TARGET:-/etc/kubernetes/manifests}

cp assets/manifests/* $MANIFESTS_TARGET
cp assets/components/etcd/etcd-static-${THIS_NODE}.yaml $MANIFESTS_TARGET
cp assets/components/haproxy/haproxy-static.yaml $MANIFESTS_TARGET
