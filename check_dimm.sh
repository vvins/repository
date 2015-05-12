#!/bin/bash
# this script checks output of hpasmcli and sends notification
# if DIMM module status is not OK. We only check modules have "Present" line in output.

#Parameters
HOST_NAME="callme-lekki-probe1"
SERVICE_NAME="DIMM condition"
NSCA_IP1="10.71.173.14"
#NSCA_IP2="172.16.37.144"

is_CRITICAL=0 

lineNumber=1
arrayIndex=2

declare -a RESULT           
declare -a failedDIMM


#Functions
#################################################################################################################################
function doDIMM {
	
	IFS=$'\n'
	
	numModules=( $(/sbin/hpasmcli -s "show dimm" | grep -c  "Module #:") )   
	#echo "numModules= $numModules"
	numLines=$((numModules*10))
	#echo "numLines= $numLines"

	RESULT=( $(/sbin/hpasmcli -s "show dimm") )   

	if  [ ${#RESULT[@]} -eq 0 ]; then        # not able to read hpasmcli output, send WARNING and exit
		PLUGIN_OUTPUT="WARNING. not able to read hpasmcli output"
		RETURN_CODE=1
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
		exit 0
	fi
	
	while [ $lineNumber -lt $numLines ]
	do
		nextIndex=$((arrayIndex+1))
		#echo "nextIndex= $nextIndex"
		Module="${RESULT[nextIndex]}"
		Module=`echo $Module | tr -s [:space:] ' '` # remove extra spaces in line
		#echo "Module= $Module"
		
		nextIndex=$((arrayIndex+2))
		#echo "nextIndex= $nextIndex"

		isUnitPresent="${RESULT[nextIndex]}"
		#echo "isUnitPresent = $isUnitPresent"

		nextIndex=$((arrayIndex+9))
		#echo "nextIndex= $nextIndex"
		isDIMMok="${RESULT[nextIndex]}"
		#echo "isDIMMok= $isDIMMok"

			if [[ $isUnitPresent == *"Yes"* ]]; then
				#total_module_present=$((total_module_present+1))
				#echo " total # of present modules= $total_module_present"
				if [[ $isDIMMok != *"Ok"* ]]; then
					#echo "Hey, some modules not working"
					is_CRITICAL=2
					failedDIMM=("${failedDIMM[@]}" "$Module")
					#echo "failed DIMM in array: ${failedDIMM[@]}"
				fi
			fi

		lineNumber=$((lineNumber+10))
		arrayIndex=$((arrayIndex+10))	

	done

	
}

#######################################################################################################################################################

function send_notification {
	#echo "SENDING NOTIFICATION"
	#echo " total # of modules = $numModules"
        #echo " total # of Present modules = $total_module_present"
        failedNum=${#failedDIMM[@]}
	total_dimm_ok=$((numModules-failedNum))	
	#echo " total number of OK dimm  = $total_dimm_ok"
	#echo "number of failed DIMM= $failedNum"
	
	if [ "$is_CRITICAL" -eq 0 ]; then
		#echo "Everything is OK"
		PLUGIN_OUTPUT="OK, total # of DIMM modules in OK condition= $total_dimm_ok , total # of DIMM modules = $numModules"
		RETURN_CODE=0
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
		#echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
		exit 0
	
	elif [ "$is_CRITICAL" -eq 2 ]; then
		
		#echo "CRITICAL. DIMM  failed: ${failedDIMM[@]}"
		PLUGIN_OUTPUT="CRITICAL. number of failed modules: $failedNum failed DIMM modules = ${failedDIMM[@]} , # of DIMM  still in OK condition= $total_dimm_ok"
		RETURN_CODE=2
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
        	#echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
		exit 0


	fi

}

###########################################################################################################################################################



#Calls

doDIMM

send_notification

exit 0
