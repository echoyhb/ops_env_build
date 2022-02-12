#!/bin/bash
# set -x

source ops_env.sh
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

service rabbitmq-server restart

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


# # 添加openstack用户
source "${CRTDIR}/config/admin-openrc"
expect <<EOF
spawn openstack user create --domain default --password-prompt glance
expect "*Password*" { send "${pwd_ops}\r" }
expect "*Repeat*" { send "${pwd_ops}\r" }
expect eof
EOF
expect <<EOF
spawn openstack user create --domain default --password-prompt placement
expect "*Password*" { send "${pwd_ops}\r" }
expect "*Repeat*" { send "${pwd_ops}\r" }
expect eof
EOF
expect <<EOF
spawn openstack user create --domain default --password-prompt nova
expect "*Password*" { send "${pwd_ops}\r" }
expect "*Repeat*" { send "${pwd_ops}\r" }
expect eof
EOF
expect <<EOF
spawn openstack user create --domain default --password-prompt neutron
expect "*Password*" { send "${pwd_ops}\r" }
expect "*Repeat*" { send "${pwd_ops}\r" }
expect eof
EOF
expect <<EOF
spawn openstack user create --domain default --password-prompt zun
expect "*Password*" { send "${pwd_ops}\r" }
expect "*Repeat*" { send "${pwd_ops}\r" }
expect eof
EOF
expect <<EOF
spawn openstack user create --domain default --password-prompt cinder
expect "*Password*" { send "${pwd_ops}\r" }
expect "*Repeat*" { send "${pwd_ops}\r" }
expect eof
EOF

# 配置 glance 
echo "配置 glance "

mysql <<EOF
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
IDENTIFIED BY '${pwd_ops}';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
IDENTIFIED BY '${pwd_ops}';
EOF

source "${CRTDIR}/config/admin-openrc"

openstack role add --project service --user glance admin
openstack service create --name glance \
  --description "OpenStack Image" image
openstack endpoint create --region RegionOne \
  image public http://controller:9292
openstack endpoint create --region RegionOne \
  image internal http://controller:9292
openstack endpoint create --region RegionOne \
  image admin http://controller:9292

cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.bak
cp "${CRTDIR}/config/glance-api.conf" /etc/glance/glance-api.conf
cp /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.bak
cp "${CRTDIR}/config/glance-registry.conf" /etc/glance/glance-registry.conf

su -s /bin/sh -c "glance-manage db_sync" glance
service glance-registry restart
service glance-api restart

# 配置 placement
echo "配置 placement"

mysql <<EOF
CREATE DATABASE placement;
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' \
IDENTIFIED BY '${pwd_ops}';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' \
IDENTIFIED BY '${pwd_ops}';
EOF

source "${CRTDIR}/config/admin-openrc"

openstack role add --project service --user placement admin
openstack service create --name placement \
  --description "Placement API" placement
openstack endpoint create --region RegionOne \
  placement public http://controller:8778
openstack endpoint create --region RegionOne \
  placement internal http://controller:8778
openstack endpoint create --region RegionOne \
  placement admin http://controller:8778

cp /etc/placement/placement.conf /etc/placement/placement.conf.bak
cp "${CRTDIR}/config/placement.conf" /etc/placement/placement.conf

su -s /bin/sh -c "placement-manage db sync" placement

service apache2 restart

# 配置 nova 
echo "配置 nova "

mysql <<EOF
CREATE DATABASE nova_api;
CREATE DATABASE nova;
CREATE DATABASE nova_cell0;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' \
  IDENTIFIED BY '${pwd_ops}';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' \
  IDENTIFIED BY '${pwd_ops}';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
  IDENTIFIED BY '${pwd_ops}';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
  IDENTIFIED BY '${pwd_ops}';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' \
  IDENTIFIED BY '${pwd_ops}';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' \
  IDENTIFIED BY '${pwd_ops}';
EOF

source "${CRTDIR}/config/admin-openrc"

openstack role add --project service --user nova admin
openstack service create --name nova \
  --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne \
  compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne \
  compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne \
  compute admin http://controller:8774/v2.1

cp /etc/nova/nova.conf /etc/nova/nova.conf.bak
cp "${CRTDIR}/config/nova.conf" /etc/nova/nova.conf

su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova

service nova-api restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

# 配置 neutron
echo "配置 neutron"

mysql <<EOF
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY '${pwd_ops}';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY '${pwd_ops}';
EOF

source "${CRTDIR}/config/admin-openrc"

openstack role add --project service --user neutron admin
openstack service create --name neutron \
  --description "OpenStack Networking" network
openstack endpoint create --region RegionOne \
  network public http://controller:9696
openstack endpoint create --region RegionOne \
  network internal http://controller:9696
openstack endpoint create --region RegionOne \
  network admin http://controller:9696

cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak
cp "${CRTDIR}/config/neutron.conf" /etc/neutron/neutron.conf
cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bak
cp "${CRTDIR}/config/ml2_conf.ini" /etc/neutron/plugins/ml2/ml2_conf.ini
cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.bak
cp "${CRTDIR}/config/linuxbridge_agent.ini" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sysctl -w net.bridge.bridge-nf-call-iptables=1
sysctl -w net.bridge.bridge-nf-call-ip6tables=1

cp /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.bak
cp "${CRTDIR}/config/l3_agent.ini" /etc/neutron/l3_agent.ini
cp /etc/neutron/dhcp_agent.ini  /etc/neutron/dhcp_agent.ini.bak
cp "${CRTDIR}/config/dhcp_agent.ini" /etc/neutron/dhcp_agent.ini 
cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.bak
cp "${CRTDIR}/config/metadata_agent.ini" /etc/neutron/metadata_agent.ini

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

service nova-api restart
service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart

# 配置horizon
echo "配置horizon"

cp /etc/openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py.bak
cp "${CRTDIR}/config/local_settings.py" /etc/openstack-dashboard/local_settings.py 

service apache2 reload

# 配置cinder
echo "配置cinder"

mysql <<EOF
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' \
  IDENTIFIED BY '${pwd_ops}';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' \
  IDENTIFIED BY '${pwd_ops}';
EOF

source "${CRTDIR}/config/admin-openrc"

openstack role add --project service --user cinder admin
openstack service create --name cinderv2 \
  --description "OpenStack Block Storage" volumev2
openstack service create --name cinderv3 \
  --description "OpenStack Block Storage" volumev3
openstack endpoint create --region RegionOne \
  volumev2 public http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne \
  volumev2 internal http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne \
  volumev2 admin http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne \
  volumev3 public http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne \
  volumev3 internal http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne \
  volumev3 admin http://controller:8776/v3/%\(project_id\)s

cp /etc/cinder/cinder.conf /etc/cinder/cinder.conf.bak
cp "${CRTDIR}/config/cinder.conf" /etc/cinder/cinder.conf

su -s /bin/sh -c "cinder-manage db sync" cinder

service nova-api restart
service cinder-scheduler restart
service apache2 restart

# 配置zun
echo "配置zun"

source "${CRTDIR}/config/admin-openrc"

mysql <<EOF
CREATE DATABASE zun;
GRANT ALL PRIVILEGES ON zun.* TO 'zun'@'localhost' \
  IDENTIFIED BY '${pwd_ops}';
GRANT ALL PRIVILEGES ON zun.* TO 'zun'@'%' \
  IDENTIFIED BY '${pwd_ops}';
EOF

openstack role add --project service --user zun admin
openstack service create --name zun \
    --description "Container Service" container
openstack endpoint create --region RegionOne \
    container public http://controller:9517/v1
openstack endpoint create --region RegionOne \
    container internal http://controller:9517/v1
openstack endpoint create --region RegionOne \
    container admin http://controller:9517/v1

groupadd --system zun
useradd --home-dir "/var/lib/zun" \
      --create-home \
      --system \
      --shell /bin/false \
      -g zun \
      zun
mkdir -p /etc/zun
chown zun:zun /etc/zun
cd /var/lib/zun
git clone -b stable/stein https://git.openstack.org/openstack/zun.git
chown -R zun:zun zun
cd zun
pip3 install -r requirements.txt
python3 setup.py install
su -s /bin/sh -c "oslo-config-generator \
    --config-file etc/zun/zun-config-generator.conf" zun
su -s /bin/sh -c "cp etc/zun/zun.conf.sample \
    /etc/zun/zun.conf" zun
su -s /bin/sh -c "cp etc/zun/api-paste.ini /etc/zun" zun

cp /etc/zun/zun.conf /etc/zun/zun.conf.bak
cp "${CRTDIR}/config/zun.conf" /etc/zun/zun.conf
chown zun:zun /etc/zun/zun.conf

su -s /bin/sh -c "zun-db-manage upgrade" zun
cp "${CRTDIR}/config/zun-api.service" /etc/systemd/system/zun-api.service
cp "${CRTDIR}/config/zun-wsproxy.service" /etc/systemd/system/zun-wsproxy.service

systemctl enable zun-api
systemctl enable zun-wsproxy
systemctl start zun-api
systemctl start zun-wsproxy



