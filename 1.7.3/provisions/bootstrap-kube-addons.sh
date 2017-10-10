#!/usr/bin/env bash

set -e

[[ -f ./vars.env ]] && . ./vars.env


cp -R assets/addons/* $ADDONS_TARGET

echo "You may need to check the following addons have been detected by addon-manager ..."
cd assets/addons && find . -mindepth 1 -type d && cd - > /dev/null
echo
kubectl get po -n kube-system
