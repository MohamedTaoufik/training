#!/bin/sh
VERSION=0.1


# Dependencies
setenforce 0
sed -i "s/Enforcing/disabled" /etc/selinux/config

sysctl -w vm.max_map_count=262144
# TODO: vm.max_map_count=262144 into /etc/sysctl.conf
if ! grep -q vm.max_map_count=262144 /etc/sysctl.conf >/dev/null ; then
	echo vm.max_map_count=262144 >> /etc/sysctl.conf
fi

systemctl stop firewalld
systemctl disable firewalld

# Dependencies
yum -y install tar  java vim net-tools

# Users/Groups
if  ! getent group opensearch > /dev/null 2>&1 ; then
	groupadd -r opensearch
fi

if ! getent passwd opensearch >/dev/null 2>&1 ; then

	useradd \
		--system \
        	--home-dir /nonexisting \
        	--gid opensearch \
                --shell /sbin/nologin \
                --comment "OpenSearch" \
                opensearch
fi


# Directories
DIRS="/usr/share/OpenSearch"
for i in $DIRS; do
	if [ ! -d $i ]; then
		mkdir -p $i
	fi
	chown -R opensearch.opensearch $i
done


# package
curl https://artifacts.opensearch.org/releases/bundle/opensearch/1.1.0/opensearch-1.1.0-linux-x64.tar.gz -o opensearch-1.1.0-linux-x64.tar.gz
tar xf opensearch-1.1.0-linux-x64.tar.gz
pushd opensearch-1.1.0
	mv * /usr/share/OpenSearch/
popd

# Disable exec in installer
sed -i "s/^exec/#exec/g" /usr/share/OpenSearch/opensearch-tar-install.sh

# Copy in our config
cp conf/opensearch.yml /usr/share/OpenSearch/config/

# %install
su -s /bin/bash opensearch -c "/usr/share/OpenSearch/opensearch-tar-install.sh" 
cp systemd/opensearch.service /usr/lib/systemd/system/opensearch.service
systemctl daemon-reload
systemctl start opensearch

