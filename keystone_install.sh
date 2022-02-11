#!/bin/bash
# set -x

source make_config.sh

# 配置 chrony
echo "配置 chrony"

cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak
cp "${CRTDIR}/config/chrony.conf" /etc/chrony/chrony.conf

service chrony restart
chronyc sources

# 配置 maridb
echo "配置 maridb"

cp "${CRTDIR}/config/99-openstack.cnf" /etc/mysql/mariadb.conf.d/99-openstack.cnf

service mysql restart

mysql_secure_installation <<EOF

n
y
${pwd_mysql}
${pwd_mysql}
n
n
n
y
EOF

# 配置rabbitmq
echo "配置rabbitmq"

rabbitmqctl add_user openstack ${pwd_ops}
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# 配置 memcached
echo "配置 memcached"

cp /etc/memcached.conf /etc/memcached.conf.bak
cp "${CRTDIR}/config/memcached.conf" /etc/memcached.conf

service memcached restart

# 配置 etcd
echo "配置 etcd"

cp /etc/default/etcd /etc/default/etcd.bak
cp "${CRTDIR}/config/etcd" /etc/default/etcd

systemctl enable etcd
systemctl restart etcd

# 配置 keystone
echo "配置 keystone"

mysql <<EOF
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY '${pwd_ops}';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY '${pwd_ops}';
EOF

cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bak
cp "${CRTDIR}/config/keystone.conf" /etc/keystone/keystone.conf

su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
keystone-manage bootstrap --bootstrap-password "${pwd_ops}" \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bak
cp "${CRTDIR}/config/apache2.conf" /etc/apache2/apache2.conf

service apache2 restart


source "${CRTDIR}/config/admin-openrc"

openstack project create --domain default \
  --description "Service Project" service


# # 添加openstack用户，此处不知道怎么在shell脚本中实现，<<eof方法不可用,执行以下命令：
# source ./config/admin-openrc
# openstack user create --domain default --password-prompt glance
# openstack user create --domain default --password-prompt placement
# openstack user create --domain default --password-prompt nova
# openstack user create --domain default --password-prompt neutron
# openstack user create --domain default --password-prompt zun
# openstack user create --domain default --password-prompt cinder