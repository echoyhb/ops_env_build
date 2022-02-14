#!/bin/bash

source ops_env.sh
source make_config.sh

# 配置 chrony
echo "配置 chrony"

cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak
cp "${CRTDIR}/config/chrony.conf" /etc/chrony/chrony.conf

service chrony restart
timedatectl set-timezone Asia/Shanghai

# 更新docker为国内源
cp "${CRTDIR}/config/daemon.json" /etc/docker/daemon.json
systemctl restart docker

# 配置 kuryr
echo "配置 kuryr"

groupadd --system kuryr
useradd --home-dir "/var/lib/kuryr" \
	--create-home \
	--system \
	--shell /bin/false \
	-g kuryr \
	kuryr

mkdir -p /etc/kuryr
chown kuryr:kuryr /etc/kuryr
cd /var/lib/kuryr
git clone -b master https://opendev.org/openstack/kuryr-libnetwork.git
chown -R kuryr:kuryr kuryr-libnetwork
cd kuryr-libnetwork
pip3 install -U pip setuptools
pip3 install --ignore-installed PyYAML pymysql
pip3 install -r requirements.txt
python3 setup.py install

su -s /bin/sh -c "./tools/generate_config_file_samples.sh" kuryr
su -s /bin/sh -c "cp etc/kuryr.conf.sample \
	/etc/kuryr/kuryr.conf" kuryr

cp /etc/kuryr/kuryr.conf /etc/kuryr/kuryr.conf.bak
cp ${CRTDIR}/config/kuryr.conf  /etc/kuryr/kuryr.conf
cp ${CRTDIR}/config/kuryr-libnetwork.service /etc/systemd/system/kuryr-libnetwork.service

systemctl enable kuryr-libnetwork
systemctl start kuryr-libnetwork

systemctl restart docker

# 配置 zun
echo "配置 zun"

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
su -s /bin/sh -c "cp etc/zun/rootwrap.conf \
	/etc/zun/rootwrap.conf" zun
su -s /bin/sh -c "mkdir -p /etc/zun/rootwrap.d" zun
su -s /bin/sh -c "cp etc/zun/rootwrap.d/* \
	/etc/zun/rootwrap.d/" zun

echo "zun ALL=(root) NOPASSWD: /usr/local/bin/zun-rootwrap \
	/etc/zun/rootwrap.conf *" | sudo tee /etc/sudoers.d/zun-rootwrap
cp /etc/zun/zun.conf /etc/zun/zun.conf.bak
cp ${CRTDIR}/config/zun.conf /etc/zun/zun.conf
mkdir -p /etc/systemd/system/docker.service.d
cp ${CRTDIR}/config/docker.conf /etc/systemd/system/docker.service.d/docker.conf

systemctl daemon-reload
systemctl restart docker
systemctl restart kuryr-libnetwork

cp ${CRTDIR}/config/zun-compute.service /etc/systemd/system/zun-compute.service

systemctl enable zun-compute
systemctl start zun-compute




