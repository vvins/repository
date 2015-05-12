#!/bin/bash

# this script  reads temporary files in /tmp created by qcx
# if field4 OR field 7 do not match 
# sends notification to nagios


#Parameters 
HOST_NAME="callme-lekki-probe1"
SERVICE_NAME="probe-links"
NSCA_IP1="10.71.173.14"

#REPORT=0
#DATE=$(date +"%Y%m%d")
#TIME=$(date +"%H%M%S")
#FILE='links_'$DATE'_'$TIME'.log'

BINS='/usr/net/Adax/qcx'
CARD=0
MAIL=()

declare -a failedLinks

#Functions
#####################################################################################################################################################
function check_links {

	while [ $CARD -le 3 ]; do
		
		$BINS/qcx_conf -s -f $BINS/qcx_conf.$CARD.hdc >> /tmp/card$CARD.log
		SYN=$(grep -c SYN /tmp/card$CARD.log)
		LOS=$(grep -c LOS /tmp/card$CARD.log)
		MAIL+=('Card: '$CARD' Links Up: '$SYN' Links Down: '$LOS)
		rm -f /tmp/card$CARD.log
		CARD=$(($CARD+1))
	done


	for MSG in "${MAIL[@]}"; do
		lineCARD=($MSG)
		#	echo " lineCARD4= ${lineCARD[4]}"
		#	echo " lineCARD7= ${lineCARD[7]}"
		if [ ${lineCARD[4]} -lt 8 ] || [ ${lineCARD[7]} -gt 0 ]; then
			failedCard=${lineCARD[0]}${lineCARD[1]}
		#	echo "failedCard = $failedCard"
			failedLinks=("${failedLinks[@]}" "$failedCard")
		fi 

		#echo -e $MSG >> $FILE
	done



	#cat /usr/local/sbin/$FILE
 }
#####################################################################################################################################################


function send_notification {
	#echo "failedLinks= ${failedLinks[@]}"
	length=${#failedLinks[@]}
	#echo "length= $length"

	if [ $length -eq 0 ]; then
	#	echo "OK"
		PLUGIN_OUTPUT="OK. All probe1 links UP"
		RETURN_CODE=0
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg

	else
	#	echo "CRITICAL"
		PLUGIN_OUTPUT="CRITICAL. some callme-lekki-probe1 links are DOWN. Reboot callme-lekki-probe1"
		RETURN_CODE=2
		echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg

	fi		


}

#########################################################################################################################################################

#Calls
check_links

send_notification

exit 0

