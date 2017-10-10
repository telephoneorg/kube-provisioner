#!/usr/bin/env bash

set -e

[[ -f ./vars.env ]] && . ./vars.env

: ${K8S_KERNEL_VERSION:=4.9.46}


echo "Strip unnecessary services ..."
apt-get purge -y --auto-remove \
    nfs-kernel-server \
    nfs-common \
    portmap \
    rpcbind \
    exim4 \
    exim4-base \
    exim4-config \
    exim4-daemon-light

systemctl daemon-reload


echo "Configuring systemd ..."
mkdir -p /etc/systemd/system.conf.d

cat <<EOF > /etc/systemd/system.conf.d/kubernetes-accounting.conf
[Manager]
DefaultCPUAccounting=yes
DefaultMemoryAccounting=yes
DefaultBlockIOAccounting=yes
EOF

systemctl daemon-reload
systemctl daemon-reexec


echo "Installing newer custom kernel v$K8S_KERNEL_VERSION ..."
tmp_dir=$(mktemp -d)
pushd $tmp_dir
    for pkg_name in headers image libc-dev; do
        curl -LO https://github.com/telephoneorg/k8s-kernel/releases/download/v${K8S_KERNEL_VERSION}/linux-${pkg_name}-${K8S_KERNEL_VERSION}-k8s_${K8S_KERNEL_VERSION}_amd64.deb
    done
    curl -LO https://github.com/telephoneorg/k8s-kernel/releases/download/v${K8S_KERNEL_VERSION}/linux-${K8S_KERNEL_VERSION}-k8s_4${K8S_KERNEL_VERSION}.dsc
    dpkg -i *.deb
    popd && rm -rf $tmp_dir


echo "Restarting now to boot new kernel ..."
systemctl reboot now
