#!/bin/bash
echo "Enter the hostname of the server you wish to add"
read HSTNAME
echo "Enter the IP address of the server you wish to add"
read IPADDR
echo "What will this be used for?"
read ALIAS
funcCheck() {
  if [ -z "`cat /usr/local/nagios/etc/servers/hosts.cfg | grep $1`" ]; then
    echo "$1 is ok"
  else
    echo "$1 already exists in config"
    exit 1
 fi
}

funcCheck $HSTNAME
funcCheck $IPADDR
cat >>/usr/local/nagios/etc/servers/hosts.cfg <<EOL
define host {
        use                             linux-server
        host_name                       $HSTNAME
        alias                           $ALIAS
        address                         $IPADDR
        max_check_attempts              5
        check_period                    24x7
        notification_interval           30
        notification_period             24x7
}
EOL
systemctl reload nagios
scp /home/cloud_user/local_deploy_nrpe_v1.01.sh cloud_user@$IPADDR:/home/cloud_user/
echo "script has been copied to $HSTNAME, now it's time to deploy it there!"
