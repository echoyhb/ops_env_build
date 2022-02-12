#!/bin/bash

## 设置zun节点环境变量

# openstack配置项统一密码 && openstack admin用户密码
pwd_ops='ics03117'

# 节点hostname
hostname=`cat /etc/hostname`

# 获取当前路径,请勿修改
CRTDIR=$(pwd)
