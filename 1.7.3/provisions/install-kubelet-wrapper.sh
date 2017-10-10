#!/usr/bin/env bash

set -e

[[ -f ./vars.env ]] && . ./vars.env

: ${KUBELET_WRAPPER_IMAGE_TAG:-v1.7.3_coreos.0}


mkdir -p /etc/kubernetes ~/.kube

systemctl is-active kubelet.service && systemctl stop kubelet.service

curl -L -o /usr/local/bin/kubelet-wrapper \
    https://raw.githubusercontent.com/coreos/coreos-overlay/master/app-admin/kubelet-wrapper/files/kubelet-wrapper
chmod +x /usr/local/bin/kubelet-wrapper


cp assets/config/kubernetes/kube-config.yaml /etc/kubernetes/
ln -sf /etc/kubernetes/kube-config.yaml ~/.kube/config


echo -e "# get image tag from https://quay.io/repository/coreos/hyperkube?tab=tags
KUBELET_IMAGE_TAG=$KUBELET_WRAPPER_IMAGE_TAG" > /etc/kubernetes/kubelet.env

if [[ -d /etc/systemd/system/kubelet.service.d ]]; then
    rm -rf /etc/systemd/system/kubelet.service.d
fi

cp assets/units/kubelet.service /etc/systemd/system/kubelet.service

systemctl daemon-reload


systemctl enable kubelet
systemctl start kubelet
systemctl status kubelet -l --no-pager
