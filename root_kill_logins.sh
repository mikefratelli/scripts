#!/bin/bash
while read line
  do
  HOST=`echo "$line" `
  SEC=`timeout 1s dsh -m -g $HOST w root |awk '{
if (NR!=1){
if($5 ~ /days/){
    split($5,d,"days");
    print $2,d[1]*5184000" sec"
}
else if( $5 ~ /:|s/){
    if ($5 ~/s/) { sub(/s/,"",$5); split($5,s,"."); print $2,s[1]" sec" }
    else if ( $5 ~/m/) { split($5,m,":"); print $2,(m[1]*60+m[2])*60" sec" }
    else { split($5,m,":"); print $2,m[1]*60+m[2]" sec" }
}
else { print $2,$5}
}}' | grep tty1 | awk '{print $2}' 2>/dev/null`
  echo "$HOST" | tee -a /tmp/phys_root_logout.log
    #Is root  logged in to HOST and if so, for how long in seconds? Is it greater than an hour?
   if [ "$SEC" -ge "3600" ] 2>/dev/null
    #If it is, then echo info and kill shell process
    then
  echo "idle time is $SEC" | tee -a /tmp/phys_root_logout.log
    HOST=`echo "$line"`
    PROCESS=`dsh -m -g $HOST ps -fu root | grep bash | grep tty | awk '{print $2}'`
    echo "Root physical console process is $PROCESS according to script" | tee -a /tmp/phys_root_logout.log
    echo "Hanging up physical console session on $HOST" | tee -a /tmp/phys_root_logout.log
    dsh -m -g "$HOST" kill -HUP "$PROCESS"
    #otherwise, just tell us that there's no idle console user
  else
    echo "no idle root console user" | tee -a /tmp/phys_root_logout.log
    fi
# The file pointing to ‘done’ should contain a list of hosts you wish to check. Have this list delimited by a line break.
  done </Users/mmorgan/testlist.txt
