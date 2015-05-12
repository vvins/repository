#!/bin/bash
# this script checks hpasmcli output
# if field 3 of the output not **NORMAL**
# sends notification

#Parameters
HOST_NAME="callme-lekki-probe1"
SERVICE_NAME="FANs condition"
NSCA_IP1="10.71.173.14"
#NSCA_IP2="172.16.37.144"

is_CRITICAL=0  
total_slots=0
total_fans=0
total_fans_running=0

declare -a RESULT           
declare -a failedFans 


#Functions
#################################################################################################################################
function doFans {

        oldIFS=$IFS
        IFS=$'\n'

        RESULT=( $(/sbin/hpasmcli -s "show fans" | grep "#") )
                #echo  "${RESULT[0]}"

        if  [ ${#RESULT[@]} -eq 0 ]; then        # not able to read hpasmcli output
                PLUGIN_OUTPUT="WARNING. not able to read hpasmcli output"
                RETURN_CODE=1
                echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
                #echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
		exit 0
        fi

        for line in "${RESULT[@]}"
        do
                IFS=$oldIFS
                line=$(echo $line)
                fields=($line)
                total_slots=$((total_slots+1)) # number of slots equil number of lines in hpasmcli output
                #echo "total_fans= $total_fans"
                fanNum="${fields[0]}"
                #echo "${fields[0]}"

                if [ "${fields[2]}" == "Yes" ]; then      # fan exists
                        total_fans=$((total_fans+1))
                        #echo "fans condition = ${fields[3]}"
                        if [ "${fields[3]}" != "NORMAL" ]; then
                                is_CRITICAL=2  # failure
                                failedFans=("${failedFans[@]}" "$fanNum")
                                #echo "failedFans= ${failedFans[@]}"
                                #echo "is_CRITICAL = $is_CRITICAL"
                        fi

                fi

        done


}

#######################################################################################################################################################

function send_notification {

        #echo " totally slots = $total_slots"
        #echo " totally fans = $total_fans"
        failedNum=${#failedFans[@]}
        total_fans_running=$((total_fans-failedNum))
        #echo " total running fans = $total_fans_running"
        #echo " total failed fans = $failedNum"

        if [ "$is_CRITICAL" -eq 0 ]; then
                #echo "Everything is OK"
                #echo " totally fans = $total_fans"
                PLUGIN_OUTPUT="OK, $total_fans_running fans normal, # of fan slots= $total_slots"
                RETURN_CODE=0
                echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
                #echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg


        elif [ "$is_CRITICAL" -eq 2 ]; then

                #echo "CRITICAL"
                PLUGIN_OUTPUT="CRITICAL. failedFans= ${failedFans[@]} , # of fans running= $total_fans_running , # of fan slots= $total_slots"
                RETURN_CODE=2
                echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
                #echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg


        fi

}

###########################################################################################################################################################



#Calls
doFans

send_notification

exit 0

