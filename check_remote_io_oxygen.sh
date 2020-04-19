#!/bin/bash
# Read Moxa IOlogik RESTful API Manual
while getopts :H:t:n:i:l: FLAG 
 do
  case ${FLAG} in
    H)
      HOSTNAME=${OPTARG}
      ;;
    t)
      # eg. AI AO DI DO
      IO=${OPTARG}
      ;;
    n)
      # eg. aiValueScaled
      NAME=${OPTARG}
      ;;
    i)
      # eg. 0 1 2 3  	    
      INDEX=${OPTARG}
      ;;
    l)
     # 19.5,20,21.5,22
     LIMITS=${OPTARG}
      ;;
  esac
done

ALARM_LOW_CRITICAL_SP=$(awk -F ',' '{print $1}' <<< $LIMITS)
ALARM_LOW_WARNING_SP=$(awk -F ',' '{print $2}' <<< $LIMITS)
ALARM_HIGH_WARNING_SP=$(awk -F ',' '{print $3}' <<< $LIMITS)
ALARM_HIGH_CRITICAL_SP=$(awk -F ',' '{print $4}' <<< $LIMITS)

ENDPOINT="http://${HOSTNAME}/api/slot/0/io/${IO}"

OUTPUT=`curl -x http://web-cache.usyd.edu.au:8080 -s /dev/null --max-time 2 -H "Content-type: application/json" -H "Accept:vdn.dac.v1" ${ENDPOINT} | jq ".io.ai" | jq -r ".[${INDEX}].${NAME}"`  #Get Output 
# OUTPUT=`awk '{printf("%.2f\n", $1)}' <<< $OUTPUT`
if [ -z "${OUTPUT// }"  ] ;
then
        echo UNKNOWN - Error: $ENDPOINT, Curl Output: $OUTPUT
	exit 3
else
	
	ALARM_LOW_CRITICAL=`bc <<< "${OUTPUT} < ${ALARM_LOW_CRITICAL_SP}"`   #Check Low Alarm
	ALARM_LOW_WARNING=`bc <<< "$OUTPUT < $ALARM_LOW_WARNING_SP"`  #Check High Alarm
        ALARM_HIGH_WARNING=`bc <<< "$OUTPUT > $ALARM_HIGH_WARNING_SP"`   #Check Low Alarm
        ALARM_HIGH_CRITICAL=`bc <<< "$OUTPUT > $ALARM_HIGH_CRITICAL_SP"`  #Check High Alarm
	# Alarm low  critical 
	if [ $ALARM_LOW_CRITICAL -ge 1 ] ;
	then
		echo "CRITICAL - Low Oxygen, Oxygen Level = $OUTPUT% | oxygen-level=$OUTPUT"
		exit 2
	        # Alarm high critical
        elif [ $ALARM_HIGH_CRITICAL -ge 1 ] ;
        then
                echo "CRITICAL - High Oxygen, Oxygen Level = $OUTPUT% | oxygen-level=$OUTPUT"
                exit 2
	
	# Alarm low warning
	elif [ $ALARM_LOW_WARNING -ge 1 ] ;
	then
        	echo "WANRING - Low Oxygen, Oxygen Level = $OUTPUT% | oxygen-level=$OUTPUT"
		exit 1
	
	# Alarm high warning
	elif [ $ALARM_HIGH_WARNING -ge 1 ] ;
	then
        	echo "WARNING - High Oxygen, Oxygen Level = $OUTPUT% | oxygen-level=$OUTPUT"
		exit 1
        else
		echo "OK - Oxygen Level = $OUTPUT% | oxygen-level=$OUTPUT"
                exit 0 
	fi
	
fi
