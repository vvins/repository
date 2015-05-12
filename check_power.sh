#!/bin/bash
# this script checks hpasmcli output
# if PSU in non Ok status sends notification to nagios


#Parameters
HOST_NAME="callme-lekki-probe1"
SERVICE_NAME="PowerSupply condition"
NSCA_IP1="10.71.173.14"
#NSCA_IP2="172.16.37.144"

is_CRITICAL=0 

lineNumber=1
arrayIndex=0

declare -a RESULT           
declare -a failedPSU

#Functions
#################################################################################################################################
function doPower {
	
	IFS=$'\n'
	
	numUnits=( $(/sbin/hpasmcli -s "show powersupply" | grep -c  "Power supply") )   
	#echo "numUnits= $numUnits"
	numLines=$((numUnits*6))
	#echo "numLines= $numLines"

	RESULT=( $(/sbin/hpasmcli -s "show powersupply") )   

	if  [ ${#RESULT[@]} -eq 0 ]; then        # not able to read hpasmcli output
		#echo "WARNING"
		PLUGIN_OUTPUT="WARNING. not able to read hpasmcli output"
		RETURN_CODE=1
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
		exit 0
	fi

	while [ $lineNumber -lt $numLines ]
	do
	Unit="${RESULT[arrayIndex]}"
	#echo "Unit= $Unit"
	nextIndex=$((arrayIndex+1))
	#echo "nextIndex= $nextIndex"
	isUnitPresent="${RESULT[nextIndex]}"
	#echo "isUnitPresent = $isUnitPresent"

	nextIndex=$((arrayIndex+3))
	#echo "nextIndex= $nextIndex"
	isUnitOK="${RESULT[nextIndex]}"
	#echo "isUnitOK= $isUnitOK"

		if [[ $isUnitPresent == *"Yes"* ]]; then
			total_psu_present=$((total_psu_present+1))
			if [[ $isUnitOK != *"Ok"* ]]; then
			#	echo "Hey, some psu are not working"
				is_CRITICAL=2
				failedPSU=("${failedPSU[@]}" "$Unit")
			#	echo "failed PSU in array: ${failedPSU[@]}"
			fi
		fi

	lineNumber=$((lineNumber+6))
	arrayIndex=$((arrayIndex+6))	

	done

	
}

#######################################################################################################################################################

function send_notification {
	
	#echo " total # of units = $numUnits"
        #echo " total # of Present units = $total_psu_present"
	#echo " total number of OK units = $total_psu_ok"
        failedNum=${#failedPSU[@]}
	#echo "number of failed PSU= $failedNum"
	total_psu_ok=$((total_psu_present-failedNum))
	
	if [ "$is_CRITICAL" -eq 0 ]; then
		#echo "Everything is OK"
		PLUGIN_OUTPUT="OK, total # of PSU running= $total_psu_ok , total # of PSU = $numUnits"
		RETURN_CODE=0
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
		#echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
	
	
	elif [ "$is_CRITICAL" -eq 2 ]; then
		
		#echo "CRITICAL. PSU failed: ${failedPSU[@]}"
		PLUGIN_OUTPUT="CRITICAL. failed PSU = ${failedPSU[@]} , # of PSU running= $total_psus_ok"
		RETURN_CODE=2
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
        	#echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg

	fi

}

###########################################################################################################################################################

#Calls
doPower

send_notification

exit 0
