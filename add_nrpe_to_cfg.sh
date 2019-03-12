#!/usr/local/bin/python3.6
##get scp working to deploy script##

### This script will add everything you need to the nagios host file to add a new ... host ###
import os
import argparse
import sys
import subprocess

CURR_USER = os.getlogin()

#When running the command, I'll also be needing the user to enter in the hostname, ip address, and alias
parser = argparse.ArgumentParser(description='Add a new host to the nrpe cfg')
parser.add_argument('hostname', help='the hostname of the server you wish to add')
parser.add_argument('ipaddr', help='the ipaddr of host you wish to add')
parser.add_argument('alias', help='the alias of the host you wish to add')
parser.add_argument("-k", "--pushkey", action='store_true', help="optional flag to push ssh key to new host (this is for the agent depoy script to push)")

args = parser.parse_args()
#important variable, this contains the hostname, ipaddress, and alias input from the user and it's been paired with strings that need to be prepended to it.
pairs = [("host_name             ", args.hostname.lower()),("address               ", args.ipaddr),("alias                 ", args.alias)]

#save the action of opening our hosts file as variable 'f'
f= open(f'/usr/local/nagios/etc/servers/hosts.cfg')
#save the action of looping through the host file line by line as 'lines'
lines = f.readlines()
#pairs contains our prepend 'x' and the user input 'y' for each tuple in 'pairs'
for x, y in pairs:
    if x != "alias                 ":
        #checking for matches from the user inputs to each line in hosts.cfg
        matches = [hst.strip() for hst in lines if y in hst.lower()]
        #if a match exists, let us know and exit the script. We don't want duplicate entries causing IP or hostname conflicts
        if matches:
            print(f"{y} already exists in config")
            sys.exit()
    # for the alias, it doesn't matter if there's a match in the cfg file or not
    elif x == "alias                 ":
        break
#all the stuff in "content" I don't want to change from config to config
content =[
        "use                   linux-server",
        "max_check_attempts    5",
        "check_period          24x7",
        "notification_interval 30",
        "notification_period  24x7",
        "}"
        ]
#save the action of writing to the *end* of hosts.cfg as 'i'
with open(f'/usr/local/nagios/etc/servers/hosts.cfg', 'a') as i:
    i.writelines("define host {\n")
    for x, y in pairs:
        #write each tuple in pairs as a new line
        i.writelines(f"{x}{y}\n")
    #write each line of 'content' next each as a new line
    i.writelines(f"%s\n" % l for l in content)
#finally, reload nagios.
#subprocess.run(["systemctl", "reload", "nagios"])
#There's another script I keep in /home/cloud_user called 'local_deploy_nrpe_v1.0h.sh' that builds the agent for you. The line below copies the script there under /home/cloud_user

if "id_rsa" in os.listdir("/home/%s/.ssh" % (CURR_USER)):
    pass
else:
    print("local SSH key does not exist, cannot push deploy script")
    sys.exit()

if args.pushkey:
    if "ssh-copy-id" in os.listdir("/usr/local/bin"):
        print(f"SSH key found. Pushing key to {args.hostname}")
        command = "ssh-copy-id -p 22 cloud_user@%s" % (args.hostname)
        subprocess.call(command, shell=True)
if "local_deploy_nrpe_v1.01.sh" in os.listdir("/home/cloud_user"):
    os.system(f"scp /home/cloud_user/local_deploy_nrpe_v1.01.sh cloud_user@{args.ipaddr}:/home/cloud_user/")
    print(f"script has been copied to {args.hostname.lower()}, now it's time to deploy it there!")
else:
    print("/home/cloud_user/local_deploy_nrpe_v1.01.sh does not exist")
