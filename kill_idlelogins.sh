#!/bin/bash

#read /usr/local/etc/group/all, per each line..
while read line
  do
#giving hostnames their own variable (might prevent race conditions?)
  HOST=`echo "$line" `
# .. per each line find out if I’m logged on, and for how long I'm idle in seconds..
  SEC=`timeout 2s dsh -m -g $HOST w mmorgan |awk '{
# translate days, minutes, hours, etc into seconds
if (NR!=1){
if($5 ~ /days/){
    split($5,d,"days");
    print $1,d[1]*5184000" sec"
}
else if( $5 ~ /:|s/){
    if ($5 ~/s/) { sub(/s/,"",$5); split($5,s,"."); print $1,s[1]" sec" }
    else if ( $5 ~/m/) { split($5,m,":"); print $1,(m[1]*60+m[2])*60" sec" }
    else { split($5,m,":"); print $1,m[1]*60+m[2]" sec" }
}
else { print $1,$5}
}}'| awk '{print $2}' | tail -n +2`
  echo "idle time is $SEC"
    #is it greater than an hour?
   if [ "$SEC " -ge "3600" ]
    #If so, then kill all my processes, so I’m logged off
    then
    echo "killing all mmorgan's processes on $HOST"
    dsh -m -g "$HOST" pkill -KILL -u 8671
    fi
  done </usr/local/etc/group/all
echo "All done"
