#!/bin/bash
# this script counts total number of messages via each probe
# if the number on one of the probe differs more than treshold from average
# sends CRITICAL 
# VVins  Feb 17, 2015
# Mar 5, 2015  added threshold function

HOST_NAME="smg1-condor-site"
SERVICE_NAME="probes-balance"
RETURN_CODE=0
NSCA_IP1="172.16.37.143"
NSCA_IP2="172.16.37.144"
today=`date +'%Y-%m-%d'`
last_min=`date -d '1 minute ago' "+%Y-%m-%d %H:%M:"`
last_hour=`date +'%H%M'`
threshold=0.5
filename="/usr/local/sbin/"$today"_probes-statistics.log"
logfile=/opt/testrouter/log/logfile.log


declare -a unbalancedProbes               # we  put unbalanced probes in the array

if [ "$last_hour" -eq "0000" ]; then
    exit 0                           # at 00:00 don't do anything
fi
################################################################################################################################################################################
function probe_traffic {
        line=`grep "$last_min" "$logfile" | grep '\[counter\]' | grep "$probe"`
        array=($line)
        CAE="${array[8]}"
        CAE=`echo "${CAE//[!0-9]/}"`
#        echo "CAE= $CAE"
        CAL="${array[9]}"
        CAL=`echo "${CAL//[!0-9]/}"`
#        echo "CAL= $CAL"
        CAR="${array[10]}"
        CAR=`echo "${CAR//[!0-9]/}"`
#       echo "CAR= $CAR"
        TOTAL=$((CAE+CAL+CAR))
        echo "$last_min probe $probe CAE= $CAE CAL= $CAL CAR= $CAR TOTAL= $TOTAL" >> "$filename"
}

function threshold {

if [ $last_hour -ge "0000" -a $last_hour -le "0700" ]
then
        threshold=0.5
        #echo "treshold= $threshold"
else
        threshold=0.25
        #echo "treshold= $threshold"
fi
}


function deviation {
        sum=$((TOTAL1+TOTAL2+TOTAL3))
        avrg=$(($sum/3))
       #echo "avrg= $avrg"
        avrg=${avrg/.*}                  # convert float to decimal
      #echo "average after converting to decimal $avrg"
        dev=$(/usr/bin/expr $avrg*$threshold | bc)              # using bc calculator to multiply and get threshold deviation
        dev=${dev/.*}                                    # convert float to decimal
      # echo "deviation after converting to decimal $dev"
}

function send_OK {
                        PLUGIN_OUTPUT="OK. probes are balanced. Total # of messages: concert-$TOTAL2 condor-$TOTAL1 elsalto-$TOTAL3 average=$avrg dev=$dev"
                        RETURN_CODE=0
                        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
                        echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg

}

function send_WARNING {
                         PLUGIN_OUTPUT="WARNING. probe(s) $line  unbalanced at $last_min --: concert-$TOTAL2 condor-$TOTAL1 elsalto-$TOTAL3 :-- average=$avrg dev=$dev"
                         RETURN_CODE=1
                         echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP1 -c /etc/nagios/send_nsca.cfg
                         echo -e "$HOST_NAME\t$SERVICE_NAME\t$RETURN_CODE\t$PLUGIN_OUTPUT" | /usr/sbin/send_nsca -H $NSCA_IP2 -c /etc/nagios/send_nsca.cfg

}

function find_unbalanced {
        diff=${diff#-}
       # echo "diff = $diff"
        if [[ "$diff" -gt "$dev" ]]
        then
                unbalancedProbes=("${unbalancedProbes[@]}" "$probe")
        fi
}

function notification {
        arrayLength=${#unbalancedProbes[@]}
        if [[ "$arrayLength" -gt 0 ]]
        then
                line=`echo ${unbalancedProbes[@]}`
               #echo "line= $line"
                send_WARNING
        else
                send_OK
        fi
}

#############################################################################################################################################################################

threshold

probe="callme-dor-probe"
probe_traffic
TOTAL1="$TOTAL"
#echo "TOTAL1= $TOTAL1"

probe="callme-crt-probe"
probe_traffic
TOTAL2="$TOTAL"
#echo "TOTAL2= $TOTAL2"

probe="callme-tmx-probe"
probe_traffic
TOTAL3="$TOTAL"
#echo "TOTAL3= $TOTAL3"

deviation

diff=$((TOTAL1-avrg))
probe="callme-dor-probe"
find_unbalanced

diff=$((TOTAL2-avrg))
probe="callme-crt-probe"
find_unbalanced

diff=$((TOTAL3-avrg))
probe="callme-tmx-probe"
find_unbalanced

notification

exit 0
