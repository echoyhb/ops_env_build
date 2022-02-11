#!/bin/bash
# set -x
apt update && apt upgrade -y
apt install -y software-properties-common dirmngr apt-transport-https
add-apt-repository cloud-archive:stein -y
apt update
apt install -y chrony 