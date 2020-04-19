#!/bin/bash

while getopts :H:h:t:d: FLAG 
 do
  case ${FLAG} in
    H)
      ADDR=${OPTARG}
      ;;
    h)
      HUMD=${OPTARG}
      ;;
    t)
      TEMP=${OPTARG}
      ;;
    d) 
      DEWP=${OPTARG}
      ;;
  esac
done

ALARM_LOW_HUMD_CRITICAL_SP=$(awk -F ',' '{print $1}' <<< $HUMD)
ALARM_LOW_HUMD_WARNING_SP=$(awk -F ',' '{print $2}' <<< $HUMD)
ALARM_HIGH_HUMD_WARNING_SP=$(awk -F ',' '{print $3}' <<< $HUMD)
ALARM_HIGH_HUMD_CRITICAL_SP=$(awk -F ',' '{print $4}' <<< $HUMD)

ALARM_LOW_TEMP_CRITICAL_SP=$(awk -F ',' '{print $1}' <<< $TEMP)
ALARM_LOW_TEMP_WARNING_SP=$(awk -F ',' '{print $2}' <<< $TEMP)
ALARM_HIGH_TEMP_WARNING_SP=$(awk -F ',' '{print $3}' <<< $TEMP)
ALARM_HIGH_TEMP_CRITICAL_SP=$(awk -F ',' '{print $4}' <<< $TEMP)

ALARM_LOW_DEWP_CRITICAL_SP=$(awk -F ',' '{print $1}' <<< $DEWP)
ALARM_LOW_DEWP_WARNING_SP=$(awk -F ',' '{print $2}' <<< $DEWP)
ALARM_HIGH_DEWP_WARNING_SP=$(awk -F ',' '{print $3}' <<< $DEWP)
ALARM_HIGH_DEWP_CRITICAL_SP=$(awk -F ',' '{print $4}' <<< $DEWP)

HUMD_OUTPUT=`snmpbulkwalk -OUneb -v2c -c public $ADDR 1.3.6.1.4.1.21239.5.1.2.1.6 | grep -oP '(?<=INTEGER: )[+-]?[0-9]+'`
TEMP_OUTPUT=`snmpbulkwalk -OUneb -v2c -c public $ADDR 1.3.6.1.4.1.21239.5.1.2.1.5 | grep -oP '(?<=INTEGER: )[+-]?[0-9]+'`
DEWP_OUTPUT=`snmpbulkwalk -OUneb -v2c -c public $ADDR 1.3.6.1.4.1.21239.5.1.2.1.7 | grep -oP '(?<=INTEGER: )[+-]?[0-9]+'`

TEMP_OUTPUT=`bc -l <<< "scale=2; $TEMP_OUTPUT / 10"`
HUMD_OUTPUT=`bc -l <<< "scale=2; $HUMD_OUTPUT"`
DEWP_OUTPUT=`bc -l <<< "scale=2; $DEWP_OUTPUT / 10"`

OUTPUT="Temperature = $TEMP_OUTPUT"C", Humidity = $HUMD_OUTPUT"%" | temperature=$TEMP_OUTPUT humidity=$HUMD_OUTPUT dew-point=$DEWP_OUTPUT"

# OUTPUT=`awk '{printf("%.2f\n", $1)}' <<< $OUTPUT`
if [ -z "${HUMD_OUTPUT// }" ] || [ -z "${TEMP_OUTPUT// }" ] || [ -z "${DEWP_OUTPUT// }" ] ;
then
        echo UNKNOWN - Error: $ADRR
	exit 3
else
	ALARM_LOW_HUMD_CRITICAL=`bc <<< "$HUMD_OUTPUT < $ALARM_LOW_HUMD_CRITICAL_SP"`   #Check Low Alarm
	ALARM_LOW_HUMD_WARNING=`bc <<< "$HUMD_OUTPUT < $ALARM_LOW_HUMD_WARNING_SP"`  #Check High Alarm
        ALARM_HIGH_HUMD_WARNING=`bc <<< "$HUMD_OUTPUT > $ALARM_HIGH_HUMD_WARNING_SP"`   #Check Low Alarm
        ALARM_HIGH_HUMD_CRITICAL=`bc <<< "$HUMD_OUTPUT > $ALARM_HIGH_HUMD_CRITICAL_SP"`  #Check High Alarm

        ALARM_LOW_TEMP_CRITICAL=`bc <<< "$TEMP_OUTPUT < $ALARM_LOW_TEMP_CRITICAL_SP"`   #Check Low Alarm
        ALARM_LOW_TEMP_WARNING=`bc <<< "$TEMP_OUTPUT < $ALARM_LOW_TEMP_WARNING_SP"`  #Check High Alarm
        ALARM_HIGH_TEMP_WARNING=`bc <<< "$TEMP_OUTPUT > $ALARM_HIGH_TEMP_WARNING_SP"`   #Check Low Alarm
        ALARM_HIGH_TEMP_CRITICAL=`bc <<< "$TEMP_OUTPUT > $ALARM_HIGH_TEMP_CRITICAL_SP"`  #Check High Alarm

        ALARM_LOW_DEWP_CRITICAL=`bc <<< "$DEWP_OUTPUT < $ALARM_LOW_DEWP_CRITICAL_SP"`   #Check Low Alarm
        ALARM_LOW_DEWP_WARNING=`bc <<< "$DEWP_OUTPUT < $ALARM_LOW_DEWP_WARNING_SP"`  #Check High Alarm
        ALARM_HIGH_DEWP_WARNING=`bc <<< "$DEWP_OUTPUT > $ALARM_HIGH_DEWP_WARNING_SP"`   #Check Low Alarm
        ALARM_HIGH_DEWP_CRITICAL=`bc <<< "$DEWP_OUTPUT > $ALARM_HIGH_DEWP_CRITICAL_SP"`  #Check High Alarm

	# Alarm low  critical 
	if [ $ALARM_LOW_HUMD_CRITICAL -ge 1 ] || [ $ALARM_LOW_TEMP_CRITICAL -ge 1 ] || [ $ALARM_LOW_DEWP_CRITICAL -ge 1 ] ||
		[ $ALARM_HIGH_HUMD_CRITICAL -ge 1 ] || [ $ALARM_HIGH_TEMP_CRITICAL -ge 1 ] || [ $ALARM_HIGH_DEWP_CRITICAL -ge 1 ]  ;
	then
		echo "Climate CRITICAL - $OUTPUT"
		exit 2

        elif [ $ALARM_LOW_HUMD_WARNING -ge 1 ] || [ $ALARM_LOW_TEMP_WARNING -ge 1 ] || [ $ALARM_LOW_DEWP_WARNING -ge 1 ] ||
                [ $ALARM_HIGH_HUMD_WARNING -ge 1 ] || [ $ALARM_HIGH_TEMP_WARNING -ge 1 ] || [ $ALARM_HIGH_DEWP_WARNING -ge 1 ]  ;
        then
                echo "Climate WARNING - $OUTPUT"
                exit 1
	else
		echo "Climate OK - $OUTPUT"
                exit 0 
	fi
	
fi
