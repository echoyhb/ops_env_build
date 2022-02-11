apt purge -y chrony python3-openstackclient mariadb-server mariadb-client python-pymysql \
	rabbitmq-server memcached python3-memcache etcd keystone glance placement-api \
	nova-api nova-conductor nova-consoleauth \
	nova-novncproxy nova-scheduler neutron-server neutron-plugin-ml2 \
	neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
	neutron-metadata-agent openstack-dashboard cinder-api cinder-scheduler
apt autoremove -y