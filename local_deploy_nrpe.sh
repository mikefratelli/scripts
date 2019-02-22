#!/bin/bash
#This script will install nrpe on a remote server for you
#You need development tools for compiling later on
yum groupinstall -y "Development tools"
#If a downloads folder exists already in your home directory, don't attempt to create one
  if [ -z  "`ls /home/$USER/downloads 2>/dev/null`"]; then
    mkdir /home/$USER/downloads
  fi
#Download nagios plugins tarball, uncompress it, and configure
cd /home/$USER/downloads && wget https://nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz#_ga=2.78936084.1450957153.1550765996-1666183519.1550251195
tar xzf /home/$USER/downloads/nagios-*
cd /home/$USER/downloads/nagios-* && /home/$USER/downloads/nagios-*/configure && make && make install
#If the user "nagios" already exists, do not attempt to create the user again
  if [ -z "`getent passwd nagios`" ]; then
    useradd nagios && groupadd nagios && usermod -a -G nagios nagios && chown nagios.nagios /usr/local/nagios && chown -R nagios.nagios /usr/local/nagios/libexec
  else
    echo "user nagios already exists"
  fi
# xinetd is the daemon that essentially runs nrpe
yum install -y xinetd
# donwload nrpe, uncompress and configure it
cd /home/$USER/downloads && wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-3.2.1/nrpe-3.2.1.tar.gz && tar zxf nrpe-3.2.1.tar.gz
cd /home/$USER/downloads/nrpe-3.2.1 && /home/$USER/downloads/nrpe-3.2.1/configure && make all && make install-groups-users && make install && make install-config && make install-inetd
#nrpe is probably not listed in /etc/services, if not, then add it
  if [ -z "` cat /etc/services | grep nrpe`" ]; then
    echo "nrpe     5666/tcp" >> /etc/services
  fi
# There's a few configurations that are wrong with nrpe out of the box, let's just change it to this so that the installation is right every time
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
# everything's been configured, restart xinetd so it can use these changes
systemctl restart xinetd.service
# These last three lines are for troubleshooting. If something went wrong, it will show here.
netstat -at | egrep "nrpe|5666"
/usr/local/nagios/libexec/check_nrpe -H localhost
/usr/local/nagios/libexec/check_nrpe -H localhost -c check_users
