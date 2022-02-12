#!/bin/bash
# set -x

# 使用配置好的ops环境变量替换模板config文件

function replace () {
    sed  -i "s#COMPUTE_MANAGEMENT_IP#${compute_management_ip}#g" "$1"
    sed  -i "s#PROVIDER_INTERFACE_NAME#${compute_provider_ifname}#g" "$1"
    sed  -i "s#PWD_OPS#${pwd_ops}#g"  "$1"
}

source ops_env.sh

if [ ! -d "config" ]; then
mkdir config
fi

cp ./config_template/* ./config
file_list=`ls ./config`
for file in $file_list
do
replace "./config/${file}"
done
