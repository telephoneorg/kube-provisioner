#!/usr/bin/env bash

set -e

[[ -f ./vars.env ]] && . ./vars.env

: ${RKT_VERSION:=1.28.1}


gpg --recv-key 18AD5014C99EF7E3BA5F6CE950BDD3E0FC8A365E

tmp_dir=$(mktemp -d)
pushd $tmp_dir
    RKT_DOWNLOAD=https://github.com/rkt/rkt/releases/download/v${RKT_VERSION}/rkt_${RKT_VERSION}-1_amd64.deb
    wget $RKT_DOWNLOAD
    wget ${RKT_DOWNLOAD}.asc
    gpg --no-tty --verify rkt_${RKT_VERSION}-1_amd64.deb.asc rkt_${RKT_VERSION}-1_amd64.deb && \
        dpkg -i rkt_*.deb
    popd

rm -rf $tmp_dir
