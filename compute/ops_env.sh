#!/bin/bash 
# set -x

# 设置 openstack 计算节点环境变量

# 控制节点管理网络ip
compute_management_ip='10.0.1.12'

# 控制节点provider网络对应的网卡名称
compute_provider_ifname='ens39'

# openstack配置项统一密码 && openstack admin用户密码
pwd_ops='ics03117'

# 获取当前路径,请勿修改
CRTDIR=$(pwd)
