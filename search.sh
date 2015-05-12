#!/bin/bash

HOSTSTATE=$1
HOSTSTATETYPE=$2
HOSTATTEMPT=$3
ADMIN_NAME='vassiliy' 
ADMIN_NAMES=('vassiliy' 'mike')
CURRENT_DATE_TIME=`date +%s`     # in secs since 1970


#function make-call(){  
while read line
do
  line=$(echo $line)                                                # to remove leading spaces and put exactly 1 space between words in line
  FC=`echo "$line" | head -c 1`                                     # first character in line - number or literal or NULL
  #echo " First character $FC"
	case "$FC" in 
		[a-zA-Z]*)                                          # first character of line is - alphabet
			if echo "$line" | grep -q "timeperiod_name"; then         
				  for i in "${ADMIN_NAMES[@]}"
				  do
					  if echo "$line" | grep -i -q "$i"; then
						  ADMIN_NAME="$i"                  # here we assign admin name on-call
						  ADMIN_NAME=${ADMIN_NAME,,}       # all letters to lower case
						  #echo "Admin_Name= $i"              
			                  fi      
				  done    
				       
			  fi
			;;

		[0-9]*)		                                     # first character of line is - number
				space=" "

				START_DATE=`echo "$line" | cut -d " " -f 1`
				END_DATE=`echo "$line" | cut -d " " -f 3`

				TIME=`echo "$line" | cut -d " " -f 4`
				START_TIME=${TIME:0:5}				
				END_TIME=${TIME:6:5}				
				
				if [ "$START_TIME" = "24:00" ]; then
					START_TIME="23:59"
				fi

				if [ "$END_TIME" = "24:00" ]; then
					END_TIME="23:59"
				fi

				FIRST_DATE_TIME=$START_DATE$space$START_TIME
				FIRST_DATE_TIME=$(echo `date --date="$FIRST_DATE_TIME" +"%s"`)   # converted to # of secs
  #echo " First date in secs  $FIRST_DATE_TIME"

				SECOND_DATE_TIME=$END_DATE$space$END_TIME
				SECOND_DATE_TIME=$(echo `date --date="$SECOND_DATE_TIME" +"%s"`) # converted no # of secs
  #echo " second date in secs  $SECOND_DATE_TIME"

				if [[ "$CURRENT_DATE_TIME" > "$FIRST_DATE_TIME" ]]; then
                                        if [[ "$CURRENT_DATE_TIME" < "$SECOND_DATE_TIME" ]]; then
                                                if [ "$ADMIN_NAME" = "vassiliy" ]; then
							echo " I called vassiliy"
#                                                        expect -c "
#                                                        set echo '-noecho';
#                                                        set timeout 20;
#                                                        spawn -noecho /usr/local/bin/linphonec -s sip:100@localhost;
#                                                        expect timeout {exit 124 } eof { exit 0 }"

                                                fi
                                                if [ "$ADMIN_NAME" = "mike" ]; then
							echo " I called mike"
#                                                        expect -c "
#                                                        set echo '-noecho';
#                                                        set timeout 20;
#                                                        spawn -noecho /usr/local/bin/linphonec -s sip:105@localhost;
#                                                       # spawn -noecho /usr/local/bin/linphonec -s sip:100@localhost;
#                                                        expect timeout {exit 124 } eof { exit 0 }"

                                                fi
                                                break
                                        fi
                               fi

			;;	

		*)  ;;
 	esac 
done < /home/vvz/timeperiod.cfg
#}




case "$HOSTSTATE" in

OK)
;;
UNREACHABLE)
;;
DOWN)
        case "$HOSTSTATETYPE" in

        SOFT)
                  case "$HOSTATTEMPT" in

                        3)
                                        make-call ;;
                        4)
                                        make-call ;;
                    esac
          ;;
        HARD)
#                  case "$HOSTATTEMPT" in
#                        5)
#                                        make-call ;;
#                   esac

           ;;
        esac
;;
esac

exit 0
