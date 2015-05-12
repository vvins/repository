#!/bin/bash
#####################################################################################################################
### this script checks /var/log/squid/access.log for "pattern" message every # minutes
### if the last message has time stamp older then 5 min from now, we believe that tunnel is down.
### it sends email about. 
###  VVins-- Dec 9, 2014
### revised -- Mar 4, 2015
#######################################################################################################################
source /usr/local/bin/env.sh
#echo $PATH
diff=0


########################################################################################################################
###  check ussdgw2 <--> proxy connection ####
currentTime=`date +%s`
#	echo "currentTime = $currentTime"
logTime=`tac /var/log/squid/access.log | grep -m 1 ' GET http://www.pagerduty.com/ ' | cut -d " " -f 1`
logTime=${logTime:0:10}
#	echo "logTime = $logTime"
diff=$((currentTime-logTime ))
	echo $diff

if [ $diff -gt 240 -a $diff -lt 300 ]; then
	 /sbin/service autossh restart
	logger autossh has been restarted TUNNEL
fi

if [ $diff -gt 300 -a $diff -lt 540 ]; then                       #300sec = 5 min
		logger TUNNEL between ussdgw2-nagios-server and PagerDuty is DOWN 
		echo "tunnel between ussdgw2-nagios-server and PagerDuty is down" | /bin/mailx -s "TUNNEL is DOWN" -r nagios-chile@starscriber.com vvins@starscriber.com mbregg@starscriber.com
fi
###############################################################################################################################
###  check billing_concert <--> proxy connection ####
currentTime=`date +%s`
#	echo "currentTime = $currentTime"
logTime=`tac /var/log/squid/access.log | grep -m 1 ' GET http://www.google.com/ ' | cut -d " " -f 1`
logTime=${logTime:0:10}
#	echo "logTime = $logTime"
diff=$((currentTime-logTime ))
	echo $diff


if [ $diff -gt 300 -a $diff -lt 540 ]; then                       #300sec = 5 min
		logger TUNNEL between vnode1 and PagerDuty is DOWN 
		echo "tunnel between vnode1-concert-site and PagerDuty is down" | /bin/mailx -s "TUNNEL is DOWN" -r nagios-chile@starscriber.com vvins@starscriber.com mbregg@starscriber.com

fi


####################################################################################################################################
# check smg1 is pingable from roma
filename2=/usr/local/bin/ping.txt  # this file to keep  number of smg1 ping attempts from roma
debug=/usr/local/bin/ping.log

if [ ! -e $filename2 ]; then
        /bin/echo 0 > $filename2
fi

result=$(nmap -sP condor-smg1 | grep "Host is up" | cut -d " " -f3)

if [ "$result" != "up" ]; then
        flag2=$(cat $filename2)

        if [ $flag2 -eq 0 ]; then
                /bin/echo 1 > $filename2
		logger VPN TUNNEL between roma and smg1 is DOWN. smg1 is NOT pingable from roma 1
        fi

        if [ $flag2 -eq 1 ]; then
                /bin/echo 2 > $filename2
		logger VPN TUNNEL between roma and smg1 is DOWN. smg1 is NOT pingable from roma 2
        fi

        if [ $flag2 -eq 2 ]; then
                /bin/echo 3 > $filename2
		logger VPN TUNNEL between roma and smg1 is DOWN. smg1 is NOT pingable from roma 3. next min will send email
        fi

        if [ $flag2 -eq 3 ]; then

                echo "condor-smg1 is not PINGable from roma" | /bin/mailx -s "smg1 is not pingable from roma" -r script@roma.starscriber.com vvins@starscriber.com
                #echo "condor-smg1 is not PINGable from roma" | /bin/mailx -s "smg1 is not pingable from roma" -r script@roma.starscriber.com mbregg@starscriber.com
                echo "$currentTime - condor-smg1 is NOT pingable. emails were sent to admins" >> $debug
                /bin/echo 4  > $filename2
        fi
else
        flag2=$(cat $filename2)
	if [ $flag2 -gt 2 ]; then
        	echo "condor-smg1 is PINGable again from roma" | /bin/mailx -s "smg1 is pingable from roma again" -r script@roma.starscriber.com vvins@starscriber.com
		logger VPN TUNNEL between roma and smg1 is UP. smg1 is pingable from roma.  
	fi
		
        /bin/echo 0 > $filename2
fi


