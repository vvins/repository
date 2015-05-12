#!/bin/bash
# this script reads *uptime* command output
# cheks thresholds and sends notification if parameter is above

#Parameters
HOST_NAME="callme-lekki-probe1"
SERVICE_NAME="Processor Load"
NSCA_IP1="10.71.173.14"
#NSCA_IP2="172.16.37.144"

declare -a output           
declare -a alertArray

threshold1=25
threshold5=23
threshold15=21

#Functions
#################################################################################################################################
function doCheck {

	output=( $(/usr/bin/uptime) )
	
	if [ -z $output ]; then  # no --uptime--output   sending UNKNOWN to nagios and exit
		#echo "UNKNOWN"
		PLUGIN_OUTPUT="WARNING. not able to read --uptime-- output"
		RETURN_CODE=1
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
		exit 0
	fi 	

	output=`echo $output | tr -s [:space:] ' '`  # remove extra spaces between words in string
	#RESULT=( $(cat ./logfile) )

	$Time="${output[0]}"
	$echo $Time
	last1="${output[9]}"
	$echo "last1 from string: $last1"
	last1=`echo ${last1%?}`            # remove last character in word (it is comma, before given to bc it should be removed)
	last1=`echo "$last1/1" | bc`
	$echo " lat1 after round:$last1"
	last5="${output[10]}"
	last5=`echo ${last5%?}`
	last5=`echo "$last5/1" | bc`
	$echo $last5
	last15="${output[11]}"
	last15=`echo "$last15/1" | bc`
	$echo $last15
	
	if [ $last1 -gt $threshold1 ]; then
		message1="last minute load is: $last1. threshold is $threshold1"
		alertArray=("${alertArray[@]}" "$message")
	elif [ $last5 -gt $threshold5 ]; then
		message5="last 5 minutes load is: $last5. threshold is $threshold5"
		alertArray=("${alertArray[@]}" "$message5")
	elif [ $last15 -gt $threshold15 ]; then
		message15="last 15 minutes load is: $last15. threshold is $threshold15"
		alertArray=("${alertArray[@]}" "$message15")
	fi
		
		
		
}

#######################################################################################################################################################

function send_notification {
	
	#echo "SENDING NOTIFICATION"
	
	
        Num=${#alertArray[@]}
	
	if [ $Num -eq 0 ]; then
	#	echo "Everything is OK message"
		PLUGIN_OUTPUT="OK, CPU load $last1.0:$last5.0:$last15.0"
		RETURN_CODE=0
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
		
	elif [ $Num -gt 0 ]; then
	#	echo "CRITICAL message ${alertArray[@]}"
		PLUGIN_OUTPUT="CRITICAL.  ${alertArray[@]}"
		RETURN_CODE=2
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
	fi

}

##########################################################################################################################################################

# Calls

doCheck
send_notification

exit 0
