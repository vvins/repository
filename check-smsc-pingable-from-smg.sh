#!/bin/bash

####################################################################################################
#if claro-smsc not pingable, CRITICAL message is sent immediately
# revised VVins Aug 14, 2014
# redone as separate service Feb 24, 2015
######################################################################################################

HOST_NAME="smg1-condor-site"
SERVICE_NAME="check-smsc-pingable-from-smg"
NSCA_IP1="172.16.37.144"
NSCA_IP2="172.16.37.143"
SMSC_IP="claro-smsc"
today=`date +'%Y-%m-%d'`
script_log_file=/usr/local/sbin/check_smsc_pingable_from_smg.log


############## check if claro-smsc pingable. if not - send CRITICAL immediately #############

last_min=`date +'%Y-%m-%d %H:%M'`

ping -c 5 $SMSC_IP > /dev/null 2> /dev/null

		if [ $? -ne 0 ]; then
			PLUGIN_OUTPUT="CRITICAL. $last_min looks like CLARO_SMSC is NOT pingable from SMG"
			RETURN_CODE=2
			echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
			echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
			echo "$last_min ERROR unable to ping claro-smsc" >> $script_log_file
            #echo "smsc is not  pingable"

		else  ##smsc pingable
			PLUGIN_OUTPUT="OK. CLARO_SMSC is pingable from SMG"
			RETURN_CODE=0
			echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
			echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
            #echo "smsc is pingable"
        fi
exit 0
