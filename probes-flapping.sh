#!/bin/bash
# this script checks number of disconnections and reconnections for each probe for the last 5 minutes
# if the number is greater than MAX_NUMBER,  it sends CRITICAL notification  to nagios
# VVins  Feb17, 2015

HOST_NAME="smg1-condor-site"
SERVICE_NAME="probes-flapping"
RETURN_CODE=0
NSCA_IP1="172.16.37.143"
NSCA_IP2="172.16.37.144"
MAX_NUMBER=5            # max number of probe flaps (disconnected + reconnected), after which CRITICAL is sent to nagios

last_hour=`date +'%H%M'`
logfile=/opt/router/log/logfile.log

if [ "$last_hour" -eq "0000" ]; then
    exit 0                           # at 00:00 don't do anything
fi


declare -a probearray   # in this array we put probes flapping

function check_flaps_number {
                        probe_disconnected="$probe:1234 is disconnected"
                        probe_reconnected="probe established connection on host $probe"

                        downs=`awk -v start="$(date --date="-5min" "+%Y-%m-%d %H:%M")" '($0 >= start)' "$logfile" | grep -c "$probe_disconnected"`
                       # echo "downs= $downs"
                        ups=`awk -v start="$(date --date="-5min" "+%Y-%m-%d %H:%M")" '($0 >= start)' "$logfile" | grep -c "$probe_reconnected"`
                       # echo "ups= $ups"
                        counter=$((ups+downs))
                       # echo "number of flaps $probe is $counter"

                        if [[ ! -z "$counter" ]]
                        then                    #not empty counter
                                if [[ "$counter" -gt "$MAX_NUMBER" ]]
                                then
                                        probearray=("${probearray[@]}" "$probe")
                                fi

                        fi

}

function send_OK {
                        PLUGIN_OUTPUT="OK. probes are NOT flapping"
                        RETURN_CODE=0
                        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
                        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg

}

function send_CRITICAL {
                         PLUGIN_OUTPUT="CRITICAL. probe(s) $line FLAPPING !!! "
                         RETURN_CODE=2
                         echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
                         echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg
}

function send_notification {
                        arrayLength=${#probearray[@]}
                        if [ "$arrayLength" -gt 0 ]
                        then
                                line=`echo ${probearray[@]}`
                                send_CRITICAL
                        else
                                send_OK
                        fi
                        }
######################################################################################################################################################
                                                                                                                                                                            
probe="callme-crt-probe2"
check_flaps_number

probe="callme-dor-probe2"
check_flaps_number

probe="callme-tmx-probe2"
check_flaps_number


send_notification

#########################################################################################################################################################


exit 0

