#!/bin/bash
apt update && apt upgrade -y 
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install -y python-pip python3-pip python python3 git expect chrony docker-ce \
	docker-ce-cli containerd.io numactl

