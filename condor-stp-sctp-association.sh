#!/bin/bash
#########################################################################################################################
# this script checks /var/log/ussdgw/server.log for MTP-PAUSE warn
# and sends CRITICAL (alert) notification if MTP-RESUME is not appeared after within some time period
# if MTP-RESUME appeared after MTP-PAUSE, WARNING message will be sent (email)
# Mar 4, 2015  VVINS
#########################################################################################################################
HOST_NAME="ussdgw1-concert-site"
SERVICE_NAME="condor-stp-sctp-association"
NSCA_IP1="172.16.37.144"
NSCA_IP2="172.16.37.143"
stp_pause="MTP-PAUSE: AffectedDpc=9846"
stp_resume="MTP-RESUME: AffectedDpc=9846"
logfile=/var/log/ussdgw/server.log
errorlog=/usr/local/sbin/error.log  # all errors for current date will be written here 

current_time=`date +'%H%M'`

if [ "$current_time" -eq "0000" ]     
then
	if [ -e "$errorlog" ]; then
    		rm -rf "$errorlog"
		exit 0                           
	fi
fi

if [ ! -e "$errorlog" ];then
	touch "$errorlog"
fi

cur_min=`date +"%H:%M:"`
					# echo "current min: $cur_min"
previous_min=`date -d '2 minute ago' +"%H:%M:"`
					# echo "previous min: $previous_min"
if [ "$previous_min" == "23:59:" ]      # log file has been rotated already 
then
    previous_min="00:00:"                       
fi

declare -a pauseArray=()
declare -a resumeArray=()
##################################################################################################################################################################

function send_notification {
                        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
                        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg

}

function check_connection {
	oldIFS=$IFS
        IFS=$'\n'                                                              # change separator from space to newline
        pauseArray=( `awk -v start="$previous_min" -v end="$cur_min" '$2>=start && $2<=end' $logfile | grep 'WARN' | grep "$stp_pause"` )
	pauseArrayLength=${#pauseArray[@]}
	# echo "pauseArrayLength: $pauseArrayLength"

	if [ "$pauseArrayLength" -eq 0 ]; then
		PLUGIN_OUTPUT="OK association between SCTP and Condor STP at $cur_min"
		RETURN_CODE=0
		send_notification
		# echo "no Pause messages for the last 2 min. sent OK"
	else
		lastelem=$((pauseArrayLength - 1))
		pausetime=`echo ${pauseArray[$lastelem]} | cut -d ' ' -f 2 `  # 20:09:55,618    -  example of what we get here
		pausesec=${pausetime:(-3)}                                       # we take part of second here = 618 (last 3 numbers in timestamp)
		# echo "pausesec: $pausesec"
		pausetime=${pausetime:0:8}                                       # hours:minutes:seconds from time 20:09:55 (first 8 characters from timestamp)
		pausetime=`echo ${pausetime//:}`                                 # remove ":" from timestamp - 200955 (we get number to compare to)
		# echo "pausetime: $pausetime"

        	resumeArray=( `awk -v start="$previous_min" -v end="$cur_min" '$2>=start && $2<=end' $logfile | grep 'WARN' | grep "$stp_resume"` )
		resumeArrayLength=${#resumeArray[@]}
		# echo "resumeArrayLength: $resumeArrayLength"

		if [ "$resumeArrayLength" -eq 0 ]; then
			PLUGIN_OUTPUT="CRITICAL. CONDOR-STP. $pauseArray[$lastelem] check $errorlog"
			# echo "PLUGIN OUTPUT: $PLUGIN_OUTPUT"
			RETURN_CODE=2
			send_notification
			echo "$pauseArray[$lastelement]" >> "$errorlog"
			# echo "Pause messages, No resume messages for the last 2 min. sent CRITICAL"
			
		else
			lastelement=$((resumeArrayLength - 1))
			resumetime=`echo ${resumeArray[$lastelement]} | cut -d ' ' -f 2 `  # 20:09:55,618    -  example of what we get here
			resumesec=${resumetime:(-3)}                                       # we take part of second here = 618 (last 3 numbers in timestamp)
			# echo "resumesec:$resumesec"                                        # we take part of second here = 618 (last 3 numbers in timestamp)
			resumetime=${resumetime:0:8}                                       # hours:minutes:seconds from time 20:09:55 (first 8 characters from timestamp)
			resumetime=`echo ${resumetime//:}`                                 # remove ":" from timestamp - 200955 (we get number to compare to)
			# echo "resumetime: $resumetime" 
			
				if [ "$resumetime" -gt "$pausetime" ]; then                 # here we check hours,minutes and secs, if they equal check decimals of sec
						PLUGIN_OUTPUT="WARNING. CONDOR-STP. MTP-PAUSE and MTP-RESUME in $logfile between $previous_min and $cur_min check $errorlog"
						RETURN_CODE=1
						send_notification
						echo "$pauseArray[$lastelem]" >> "$errorlog"
						echo "$resumeArray[$lastelement]" >> "$errorlog"
						#echo "Pause messages and Resume messages. Resume after Pause. sent WARNING"
				
				elif [ "$resumetime" -eq "$pausetime" ]; then
					if [ "$resumesec" -gt "$pausesec" ]; then           # here we check decimals of secs
						PLUGIN_OUTPUT="WARNING. CONDOR-STP. MTP-PAUSE and MTP-RESUME in $logfile between $previous_min and $cur_min check $errorlog"
						RETURN_CODE=1
						send_notification
						echo "$pauseArray[$lastelem]" >> "$errorlog"
						echo "$resumeArray[$lastelement]" >> "$errorlog"
						# echo "Pause messages and Resume messages. Resume after Pause. checked decimals of secs. sent WARNING"
					else
						PLUGIN_OUTPUT="CRITICAL. CONDOR-STP. $pauseArray[$lastelem] check $errorlog"
						RETURN_CODE=2
						send_notification
						echo "$pauseArray[$lastelem]" >> "$errorlog"
						# echo "Pause messages and Resume messages. Pause after Resume. checked decimals of secs. sent CRITICAL"
					fi


				else [ "$resumetime" -lt "$pausetime" ];
					PLUGIN_OUTPUT="CRITICAL. CONDOR-STP. $pauseArray[$lastelem] check $errorlog"
					RETURN_CODE=2
					send_notification
					echo "$pauseArray[$lastelem]" >> "$errorlog"
					# echo "Pause messages and Resume messages. Pause after Resume. sent CRITICAL"
					
				fi
			
		fi
		
		
		
	fi
	IFS=$oldIFS
}

check_connection

exit 0
