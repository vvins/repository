#!/bin/bash

source /usr/local/bin/env.sh

currentTime=`date +"%Y-%m-%d %H:%M"`

#echo $currentTime

result=`service autossh status | grep -q 'is running'`


status=$?
if [ $status -ne 0 ]; then
	echo "autossh service is not running on roma" | /bin/mailx -s "autossh is not running on roma" -r roma-autossh@starscriber.com vvins@starscriber.com 
	echo "$currentTime autossh service is not running on roma" >> /usr/local/bin/autossh.log 
fi


