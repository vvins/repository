#!/bin/bash

source /usr/local/sbin/env.sh

HOST_NAME="ussdgw1-concert-site"
NSCA_IP1="172.16.37.144"
NSCA_IP2="172.16.37.143"
SERVICE_NAME="ussdgw-daemon-running"

daemon_previous_status='/usr/local/sbin/ussdgwd.txt'
daemon_log='/usr/local/sbin/ussdgwd.log'
currentTime=`date +"%Y-%m-%d %H:%M"`

####################################################################################################################################################################
if [ ! -e $daemon_previous_status ]; then
        /bin/echo 0 > $daemon_previous_status
fi

if [ ! -e $daemon_log ]; then
        /bin/echo "$currentTime started ussdgwd run.jar logging"  > $daemon_log
fi
#####################################################################################################################################################################
function send_OK {
# sending OK to nagios
	RETURN_CODE=0
        PLUGIN_OUTPUT="OK. ussdgw1 daemon is running . . ." 
        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg

}


function send_CRITICAL {
# sending CRITICAL to nagios
		RETURN_CODE=2
                PLUGIN_OUTPUT="CRITICAL. ussdgw1 daemon is NOT running"
                echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
                echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
}


function send_WARNING {
# sending CRITICAL to nagios
		RETURN_CODE=1
                PLUGIN_OUTPUT="WARNING. ussdgw1 daemon is NOT running?"
                echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
                echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
}

function start_ussdgwd {
# starting ussdgw daemon

/opt/telscale/ussdgw-6.1.6.GA/jboss-5.1.0.GA/bin/ussdgwd start

}


function ussdgwd_status {
# grep if run.jur process  is running
# if not, check previous daemon status,
# first - try to restart daemon
# second - alarm nagios

status=`ps aux | grep '/opt/telscale/ussdgw/jboss-5.1.0.GA/bin/run.jar' | grep -v grep`

if [ "$?" -ne 0 ]; then
	flag=$(cat $daemon_previous_status)
	echo "not equil 0"
	if [ "$flag" -eq 0 ]; then

		logger USSDGWD DAEMON is down. restarting  
		start_ussdgwd      # first time defined that process is not running, trying to start
        	/bin/echo "$currentTime ussdgwd is down. restarting ..."  >> $daemon_log
		/bin/echo 1 > $daemon_previous_status
		send_WARNING
	
	fi

	if [ "$flag" -eq 1 ]; then
		send_CRITICAL     # second time defined the process is not running, sending alert to nagios
		/bin/echo 2 > $daemon_previous_status
		/opt/telscale/ussdgw-6.1.6.GA/jboss-5.1.0.GA/bin/ussdgwd start
		logger USSDGWD DAEMON is down. sending alert
        	/bin/echo "$currentTime ussdgwd is still down. failed to restart. sending alert to nagios"  >> $daemon_log
	
	fi

	if [ "$flag" -eq 2 ]; then
		/bin/echo 3 >  $daemon_previous_status
		logger USSDGWD DAEMON is down. sending email 
		echo "ussdgwd1 daemon run.jar is DOWN " | /bin/mailx -s "ussdgw1 daemon is DOWN" -r script@ussdgw1.starscriber.com vvins@starscriber.com	
		send_WARNING
	fi
else
	echo "equil 0"
	flag=$(cat $daemon_previous_status)

	if [ "$flag" -gt 2 ]; then

		/bin/echo 0 >  $daemon_previous_status
		send_OK
		
	fi

	/bin/echo 0 >  $daemon_previous_status
	send_OK
		
fi
}
###########################################################################################################################################################################

ussdgwd_status


exit 0
