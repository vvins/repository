#!/bin/bash
# this script checks hpasmcli output
# if temperature above threshold - sends CRITICAL,
# if current temp 10% below threshold  - sends WARNING 

#Parameters
HOST_NAME="callme-lekki-probe1"
SERVICE_NAME="TEMPERATURE condition"
NSCA_IP1="10.71.173.14"
#NSCA_IP2="172.16.37.144"

lineNumber=3
arrayIndex=2

declare -a RESULT           
declare -a alertArea
declare -a warnArea

#Functions
#################################################################################################################################
function doTemp {
	oldIFS=$IFS	
	IFS=$'\n'
	
		
	numLines=( $(/sbin/hpasmcli -s "show temp" | wc -l) )   
#	echo "number of lines = $numLines"

	RESULT=( $(/sbin/hpasmcli -s "show temp") )
	
	if  [ ${#RESULT[@]} -eq 0 ]; then        # not able to read hpasmcli output
		
		PLUGIN_OUTPUT="WARNING. not able to read hpasmcli output"
		RETURN_CODE=1
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
		exit 0
	fi 	

	while [ $lineNumber -lt $numLines ]
	do	
#echo $lineNumber
#echo $arrayIndex
		IFS=$oldIFS
		line=${RESULT[arrayIndex]}		
		line=($line)
		SensorField="${line[0]}"
		#echo $SensorField
		LocationField="${line[1]}"
		#echo $LocationField
		TempField="${line[2]}"
		#echo "echo TempField = $TempField"
		ThresholdField="${line[3]}"
		#echo "thresholdfield =$ThresholdField"

		if [[ $TempField == *"-"*  ||  $ThresholdField == *"-"* || $TempField == "" || ThresholdField == "" ]]; then

			lineNumber=$((lineNumber+1))
			arrayIndex=$((arrayIndex+1))	
			continue                                                 # we don't have values for temperature in output

		fi

		arrayTemp=(${TempField//C/ })   # split field using "C" as delimiter
		currentTemp=${arrayTemp[0]}				
		#echo "currentTemp= $currentTemp" 
			
		arrayThreshold=(${ThresholdField//C/ }) # split field using "C" as delimiter	
		currentThreshold=${arrayThreshold[0]}
		#echo "currentThreshold= $currentThreshold"		

		warningThreshold=`echo "($currentThreshold*0.1)/1" | bc`  # need to devide  - to get rounded integer
		#echo "warningThresholddeviation= $warningThreshold"

		warningThreshold=$((currentThreshold-warningThreshold))
		#echo "warningThreshold= $warningThreshold"
		
		if [ $currentTemp -ge $currentThreshold ]; then

			alert=$SensorField$LocationField    # will be easier to read output
			alertArea=("${alertArea[@]}" "$alert")	
		fi

		if [ $currentTemp -ge $warningThreshold -a $currentTemp -lt $currentThreshold ]; then

			alert=$SensorField$LocationField    # will be easier to read output
			warnArea=("${warnArea[@]}" "$alert")	
			
			
		fi
		
		lineNumber=$((lineNumber+1))
		arrayIndex=$((arrayIndex+1))	

	done

	
}

#######################################################################################################################################################

function send_notification {
	
#	echo "SENDING NOTIFICATION"
	
	
        failedNum=${#alertArea[@]}

	if [ $failedNum -gt 0 ]; then
		#echo "CRITICAL message"
		PLUGIN_OUTPUT="CRITICAL. check ${alertArea[@]}   temperature above threshold"
		RETURN_CODE=2
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
		exit 0
	fi

	failedNum=${#warnArea[@]}
	
	if [ $failedNum -gt 0 ]; then
		#echo "WARNING message"
	
		PLUGIN_OUTPUT="WARNING. check ${warnArea[@]}   temperature above warning threshold"
		RETURN_CODE=1
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
		exit 0

	fi
	

#	echo "Everything is OK message"
	PLUGIN_OUTPUT="OK, temperature in all areas"
	RETURN_CODE=0
	echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
	#echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
}

##########################################################################################################################################################


#Calls
doTemp

send_notification

exit 0
