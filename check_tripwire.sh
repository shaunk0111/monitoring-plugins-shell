#!/bin/bash

## Comment ##

# Check the integrity of system with the tripwire --check command
# In tripwire integrity check mode, the return code is a set of
#  bits OR'd together to indicate the check result:
# 1: At least one file or directory was added.
# 2: At least one file or directory was removed.
# 4: At least one file or directory was modified.
# 8: At least one error occurred during the check.
# So if an integrity check returns 0, it means the check ran
#  successfully and no changes were observed.

## Arugments ##

while getopts ":R:" opt; do

  case ${opt} in
    R )
      RULE=${OPTARG}
      ;;
  esac
done

## Check tripwire ##


if [ -z "$RULE"  ] ; #Check option 

then
	RESULTS=`sudo tripwire --check`
else
	RESULTS=`sudo tripwire --check --rule-name "$RULE"`
fi


RESULTS=`sudo tripwire --check --rule-name "$RULE"`

STATE=$?

case "$STATE" in

0)  
    echo "$RULE OK - No violations | state=$STATE"
    exit 0
    ;;

[1-7])  
    echo "$RULE WARNING - Violations found | state=$STATE"
    exit 1
    ;;

*) 
    echo "$RULE UNKNOWN - Error occured | state=$STATE"
    exit 3
   ;;

esac
