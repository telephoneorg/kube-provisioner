#!/bin/bash

KUBERNETES_VERSION=1.4.6

curl -sSL -o /usr/local/bin/kubectl \
    https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/darwin/amd64/kubectl

chmod +x /usr/local/bin/kubectl
