#!/usr/bin/env bash

set -e

[[ -f ./vars.env ]] && . ./vars.env

: ${DOCKER_VERSION:=1.12.6}

RELEASE=$(. /etc/os-release; echo "$ID")

apt-get install -y \
    apt-transport-https \
    software-properties-common \
    lsb-release

curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -
# apt-key adv —-keyserver hkp://p80.pool.sks-keyservers.net:80 —-recv-keys 58118E89F3A912897C070ADBF76221572C52609D
add-apt-repository "deb [arch=amd64] https://apt.dockerproject.org/repo debian-${RELEASE} main"
apt-get update -y

apt_version=$(apt-cache madison docker-engine | grep $DOCKER_VERSION | awk '{print $3}')
echo "Installing docker v$apt_version"
apt-get install -y docker-engine==$apt_version


cp assets/config/docker/daemon.json /etc/docker/
mkdir -p /etc/systemd/system/docker.service.d
cp assets/units/docker.service.d/*.conf /etc/systemd/system/docker.service.d/

systemctl daemon-reload

systemctl enable docker
systemctl restart docker
systemctl status docker -l --no-pager
