#!/bin/bash
# set -x
apt update && apt upgrade -y
apt install -y software-properties-common dirmngr apt-transport-https
add-apt-repository cloud-archive:stein -y
apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mirrors.aliyun.com/mariadb/repo/10.4/ubuntu bionic main'
apt update
apt install -y  python-pip python3-pip python python3 git \
	chrony python3-openstackclient mariadb-server mariadb-client python-pymysql \
	rabbitmq-server memcached python3-memcache etcd keystone glance placement-api \
	nova-api nova-conductor nova-consoleauth \
	nova-novncproxy nova-scheduler neutron-server neutron-plugin-ml2 \
	neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
	neutron-metadata-agent openstack-dashboard cinder-api cinder-scheduler --fix-missing
