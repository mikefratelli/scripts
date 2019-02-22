#!/bin/bash
#This script will install nrpe on a remote server for you
yum groupinstall -y "Development tools"
if [ -z  "`ls /home/cloud_user/downloads 2>/dev/null`"]; then
mkdir /home/cloud_user/downloads
fi
cd /home/cloud_user/downloads && wget https://nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz#_ga=2.78936084.1450957153.1550765996-1666183519.1550251195
tar xzf /home/cloud_user/downloads/nagios-*
cd /home/cloud_user/downloads/nagios-* && /home/cloud_user/downloads/nagios-*/configure && make && make install
if [ -z "`getent passwd nagios`" ]; then
useradd nagios && groupadd nagios && usermod -a -G nagios nagios && chown nagios.nagios /usr/local/nagios && chown -R nagios.nagios /usr/local/nagios/libexec
else
echo "user nagios already exists"
fi
 yum install -y xinetd
 cd /home/cloud_user/downloads && wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-3.2.1/nrpe-3.2.1.tar.gz && tar zxf nrpe-3.2.1.tar.gz
 cd /home/cloud_user/downloads/nrpe-3.2.1 && /home/cloud_user/downloads/nrpe-3.2.1/configure && make all && make install-groups-users && make install && make install-config && make install-inetd
if [ -z "` cat /etc/services | grep nrpe`" ]; then
 echo "nrpe     5666/tcp" >> /etc/services
fi
 cat > /etc/xinetd.d/nrpe << EOL
 service nrpe
{
    disable         = no
    socket_type     = stream
    port            = 5666
    wait            = no
    user            = nagios
    group           = nagios
    server          = /usr/local/nagios/bin/nrpe
    server_args     = -c /usr/local/nagios/etc/nrpe.cfg --inetd
    only_from       = 127.0.0.1 ::1
    log_on_success  =
}
EOL
 systemctl restart xinetd.service
 netstat -at | egrep "nrpe|5666"
 /usr/local/nagios/libexec/check_nrpe -H localhost
 /usr/local/nagios/libexec/check_nrpe -H localhost -c check_users
