#!/bin/bash 
# set -x

# 设置 openstack 环境变量

# 控制节点管理网络子网
controller_management_subnet='10.0.1.0\/24'

# 控制节点管理网络ip
controller_management_ip='10.0.1.11'

# 控制节点provider网络对应的网卡名称
controller_provider_ifname='ens39'

# mysql数据库root密码
pwd_mysql='ics03117'

# openstack配置项统一密码 && openstack admin用户密码
pwd_ops='ics03117'

# 获取当前路径,请勿修改
CRTDIR=$(pwd)
