#!/bin/bash
# this script checks whether probes are connected to router 
# if not or traffic through probe = 0 sends CRITICAL to nagios
# VVins  Feb17, 2015
# revised Feb 25, 2015
# revised April 27, 2015 after nagios installation on vnode1, vnode2
# revised May 8, 2015.  now script checks condor-probe not condor-probe 1 or 2
# if no output of grep (string is empty) sends notifications about also

HOST_NAME="smg1-condor-site"
SERVICE_NAME="probe-router-traffic"
NSCA_IP1="172.16.37.143"
NSCA_IP2="172.16.37.144"
#logfile=/usr/local/sbin/log
logfile=/opt/testrouter/log/logfile.log

## in the beginning of each 24h skip first minute
last_hour=`date +'%H%M'`                           # at 00:00 log files rotation, so 23:59 values are not readable

if [ "$last_hour" -eq "0000" ]; then exit 0 ; fi   # at 00:00 just leave a script

last_min=`date -d '1 minute ago' "+%Y-%m-%d %H:%M:"`
echo "previous minute $last_min"

declare -a probes_down   

##########################################################################################################################################################################

function probe_traffic {

line=`grep "$last_min" "$logfile" | grep '\[counter\]' | grep "$probe"`

if [ ! -z "$line" ]  # probe #1 or #2 is connected to router
then
        array=($line)
        CAE="${array[8]}"
        CAE=`echo "${CAE//[!0-9]/}"`
        echo "CAE= $CAE"
        CAL="${array[9]}"
        CAL=`echo "${CAL//[!0-9]/}"`
        echo "CAL= $CAL"
        CAR="${array[10]}"
        CAR=`echo "${CAR//[!0-9]/}"`
        echo "CAR= $CAR"
        TOTAL=$((CAE+CAL+CAR))
        echo "TOTAL $probe = $TOTAL"

        if [ $TOTAL -eq 0 ]; then
                probes_down=("${probes_down[@]}" "$probe")
        fi
else
#        echo "No $probe record in router log at $last_min !!!!"
        PLUGIN_OUTPUT="No $probe record in router log at $last_min !!!!"
        RETURN_CODE=2
        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
        exit 0 
fi
        
}

function send_notification {

    arrayLength=${#probes_down[@]}
    if [ "$arrayLength" -gt 0 ]
    then
        arrayContent=`echo ${probes_down[@]}`
        #echo "probe(s) $arrayContent are down. Total # of messages through  = 0"
        PLUGIN_OUTPUT="probe(s) $arrayContent are down. Total # of messages through  = 0"
        RETURN_CODE=2
        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
    else
    #    echo "OK. All probes Ok. Total traffic --> concert:$TOTAL1, --> condor:$TOTAL2, --> elsalto:$TOTAL3"
        PLUGIN_OUTPUT="OK. All probes Ok. Total traffic --> concert:$TOTAL1, --> condor:$TOTAL2, --> elsalto:$TOTAL3"
        RETURN_CODE=0
        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
    fi

}
###########################################################################################################################################################################


probe="callme-crt-probe"
probe_traffic
TOTAL1=$TOTAL

probe="callme-dor-probe"
probe_traffic
TOTAL2=$TOTAL

probe="callme-tmx-probe"
probe_traffic
TOTAL3=$TOTAL

send_notification

exit 0

