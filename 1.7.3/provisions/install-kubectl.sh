#!/usr/bin/env bash

set -e

[[ -f ./vars.env ]] && . ./vars.env

: ${KUBERNETES_VERSION:=1.7.3}
: ${OS:=$(uname -s | awk '{print tolower($0)}')}


curl -sSL -o /usr/local/bin/kubectl \
    https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/$OS/amd64/kubectl
chmod +x /usr/local/bin/kubectl
