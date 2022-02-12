#!/bin/bash
# set -x

source ops_env.sh
source make_config.sh

# 配置 chrony
echo "配置 chrony"

cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak
cp "${CRTDIR}/config/chrony.conf" /etc/chrony/chrony.conf

service chrony restart

# 配置 nova
echo "配置 nova"

cp /etc/nova/nova.conf /etc/nova/nova.conf.bak
cp "${CRTDIR}/config/nova.conf" /etc/nova/nova.conf

service nova-compute restart

# 配置 neutron
echo "配置 neutron"

cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak
cp "${CRTDIR}/config/neutron.conf" /etc/neutron/neutron.conf
cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.bak
cp "${CRTDIR}/config/linuxbridge_agent.ini" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sysctl -w net.bridge.bridge-nf-call-iptables=1
sysctl -w net.bridge.bridge-nf-call-ip6tables=1

service nova-compute restart
service neutron-linuxbridge-agent restart

