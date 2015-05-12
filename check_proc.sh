#!/bin/bash
#this script checks hpasmcli output 
# if processor status !OK sends notification to nagios

#Parameters
HOST_NAME="callme-lekki-probe1"
SERVICE_NAME="Processors condition"
NSCA_IP1="10.71.173.14"
#NSCA_IP2="172.16.37.144"

is_CRITICAL=0 

lineNumber=1
arrayIndex=0

declare -a RESULT           
declare -a failedProcessor

#Functions
#################################################################################################################################
function doProc {
	
	IFS=$'\n'
	
	System=( $(/sbin/hpasmcli -s "show server" | grep   "System") )   
	System=`echo $System | tr -s [:space:] ' '`
		
	numProc=( $(/sbin/hpasmcli -s "show server" | grep -c  "Processor:") )   
	#echo "numProc= $numProc"
	numLines=$((numProc*10))
	#echo "numLines= $numLines"

	RESULT=( $(/sbin/hpasmcli -s "show server" | grep -A10 "Processor:") )
	
	if  [ ${#RESULT[@]} -eq 0 ]; then        # not able to read hpasmcli output
		
		#echo "WARNING"
		PLUGIN_OUTPUT="WARNING. not able to read hpasmcli output"
		RETURN_CODE=1
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
        	##echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
		exit 0

	fi

	while [ $lineNumber -lt $numLines ]
	do
		#echo "arrayIndex =$arrayIndex"
		Processor="${RESULT[arrayIndex]}"
		Processor=`echo $Processor | tr -s [:space:] ' '`
		#echo "Processor= $Processor"

		nextIndex=$((arrayIndex+10))
		#echo "nextIndex= $nextIndex"
		Status="${RESULT[nextIndex]}"
		#echo "processor Status= $Status"

				if [[ $Status != *"Ok"* ]]; then
					#echo "Hey, processor is failed"
					is_CRITICAL=2
					failedProcessor=("${failedProcessor[@]}" "$Processor")
					#echo "failed Processors in array: ${failedProcessor[@]}"
				fi

		lineNumber=$((lineNumber+12))
		arrayIndex=$((arrayIndex+12))	

	done

	
}

#######################################################################################################################################################

function send_notification {
	#echo "SENDING NOTIFICATION"
	#echo " total # of processors = $numProc"
        ##echo " total # of Present modules = $total_module_present"
        failedNum=${#failedProcessor[@]}
	total_proc_ok=$((numProc-failedNum))	
	#echo " total number of OK processors  = $total_proc_ok"
	#echo "number of failed proc= $failedNum"
	
	if [ "$is_CRITICAL" -eq 0 ]; then
		#echo "Everything is OK"
		PLUGIN_OUTPUT="OK, All processors: $numProc Ok.   $System"
		RETURN_CODE=0
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
		##echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
		exit 0
	
	elif [ "$is_CRITICAL" -eq 2 ]; then
		
		#echo "CRITICAL. Processor(s) failed: ${failedProcessor[@]}"
		PLUGIN_OUTPUT="CRITICAL. # of processors failed=$failedNum failed Processor(s) is:${failedProcessor[@]} total # of processors:$numProc $System"
		RETURN_CODE=2
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
        	##echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
		exit 0


	fi

}

###########################################################################################################################################################


#Calls
doProc

send_notification

exit 0
