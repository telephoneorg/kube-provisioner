#!/bin/bash

apt-get install -y fakeroot kernel-package linux-source-3.16 libncurses5-dev

apt-get build-dep linux -y
apt-get source linux -y

cd linux-*