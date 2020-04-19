#!/bin/bash

# Default values
TIMEOUT=5
WARNING=10
CRITICAL=10

while getopts :H:t:w:c:V FLAG 
 do
  case ${FLAG} in
    H)
      HOSTNAME=${OPTARG}
      ;;
    t)
      TIMEOUT=${OPTARG}
      ;;
    w)
      WARNING=${OPTARG}
      ;;
    c) 
      CRITICAL=${OPTARG}
      ;;
    V) echo Version 1.0, Published 12-04-19 
       exit 0    
  esac
done

ENDPOINT="http://${HOSTNAME}/api/"

OUTPUT=`curl --retry 3 -x http://web-cache.usyd.edu.au:8080 -s /dev/null --max-time $TIMEOUT -H "Content-type: application/json" -H "Accept:vdn.dac.v1" ${ENDPOINT} | jq -r '.["data"] | .["dev"] | .[] | .["analog"] | .["0"] | .["value"] | select (.!=null)' ` 

OUTPUT=`bc -l <<< "scale=2; $OUTPUT/1"`

if [ -z "${OUTPUT// }"  ] ; #Check connection failure
then
        echo UNKNOWN - Error: $ENDPOINT, Curl Output: $OUTPUT
        exit 3
else
        # Check states
        WARNING=`bc <<< "$OUTPUT >= $WARNING"`    
        CRITICAL=`bc <<< "$OUTPUT >= $CRITICAL"` 

	# Alarm low warning
        if [ $CRITICAL -ge 1 ] ;
        then
                echo "CRITICAL - Alarm on | state=$OUTPUT"
                exit 1

        # Alarm high warning
        elif [ $WARNING -ge 1 ] ;
        then
                echo "WARNING - Alarm on | state=$OUTPUT"
                exit 1
        else
                echo "OK - Alarm off | state=$OUTPUT"
                exit 0

        fi
fi

