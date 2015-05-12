#!/bin/bash

####################################################################################################
#this script checks smg log file (/opt/smg/log/logFile.log)  every minute (check crontab) for OUT messages
#if no OUT messages for the last minute sends critical to nagios
# revised VVins Feb 24, 2015
######################################################################################################

source /usr/local/sbin/env.sh

HOST_NAME="smg1-condor-site"
SERVICE_NAME="check-smg-out-passive"
NSCA_IP1="172.16.37.144"
NSCA_IP2="172.16.37.143"
logfile=/opt/smg/log/logFile.log
today=`date +'%Y-%m-%d'`
last_hour=`date +'%H%M'`   
last_min=`date -d '1 minute ago' "+%Y-%m-%d %H:%M:"`
script_log_file="/usr/local/sbin/"$today"_smg-statistics.log"

#######################################################################################################################################################################
function send_OK {
                        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
                        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg

}

function send_CRITICAL {
                         echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
                         echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg

}

function smg_OUT {
    number_of_messages=`grep "$last_min" "$logfile" | grep -c "OUT:"`
    echo "$last_min number of smg OUT messages in log file $number_of_messages" >> $script_log_file
    
}

#########################################################################################################################################################################


if [ "$last_hour" -eq "0000" ]; then exit 0 ; fi   # at 00:00 log rotation,  just leave a script

smg_OUT

echo " number of messages: $number_of_messages"

if [ "$number_of_messages" -eq 0 ]; then
    PLUGIN_OUTPUT="CRITICAL. no smg OUT messages at $last_min"
    RETURN_CODE=2
    send_CRITICAL
#    echo "sent critical"
else 
	PLUGIN_OUTPUT="OK. smg sent $number_of_messages 'OUT' messages at $last_min"
	RETURN_CODE=0
    send_OK
 #   echo " sent OK "
fi

exit 0
