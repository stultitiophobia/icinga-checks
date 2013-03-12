#!/bin/bash

if [ ! "$#" == "3" ]; then
    	echo -e "QNap-NAS-monitoring for icinga v. 1.2 - (C) 2011 Martin Fuchs - https://github.com/trendchiller/icinga-checks\n\nusage : ./check_qnap.sh <hostname> <snmp_community> <check>\nchecks: cpu, diskusage, fan, hdsmart, hdtemp, volumes, systemp, ramuse \n" && exit "3"
fi
strHostname=$1
strCommunity=$2
strCheck=$3

# -> DISKUSAGE -----------------------------------------------------------------
if [ "$strCheck" == "diskusage" ]; then
    	disk=$(snmpget -v1 -c $strCommunity -mALL $strHostname .1.3.6.1.2.1.25.2.3.1.5.33 | awk '{print $4}')
    	used=$(snmpget -v1 -c $strCommunity -mALL $strHostname .1.3.6.1.2.1.25.2.3.1.6.33 | awk '{print $4}')
		let "PERC=(($used*100)/$disk)"
		strOutput="Belegt=$[PERC]%|'Belegt'=$[PERC]%;80;90;0;100"
    	if [ $PERC -ge "90" ]; then
      	echo "CRITICAL: "$strOutput
      	exit 2
    	fi
    	if [ $PERC -ge "80" ]; then
      	echo "WARNING: "$strOutput
      	exit 1
    	fi
      	echo "OK: "$strOutput
      	exit 0

# -> CPU -----------------------------------------------------------------------
elif [ "$strCheck" == "cpu" ]; then
    	CPU=$(snmpget -v1 -c $strCommunity -mALL $strHostname 1.3.6.1.4.1.24681.1.2.1.0 | awk '{print $4}' | sed 's/.\(.*\).../\1/')
    	strOutput="CPU: $[CPU]%|'CPU'=$[CPU]%;80;90;0;100"
    	if [ $CPU -ge "90" ]; then
      	echo "CRITICAL: "$strOutput
      	exit 2
    	fi
    	if [ $CPU -ge "80" ]; then
      	echo "WARNING: "$strOutput
      	exit 1
    	fi
      	echo "OK: "$strOutput
      	exit 0

# -> HDD SMART Status ----------------------------------------------------------
elif [ "$strCheck" == "hdsmart" ]; then
      HDNUM=$(snmpget -v1 -c $strCommunity -mALL "$strHostname" .1.3.6.1.4.1.24681.1.2.10.0 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
      i=1
      while [ $i -le $HDNUM ]
      do
        HD[$i]=$(snmpget -v1 -c $strCommunity -mALL "$strHostname" 1.3.6.1.4.1.24681.1.2.11.1.7.$i | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
        let i=i+1
      done

      FLAG=0
      SMART="SMART-Status: "
      for i in ${HD[@]}
      do
        [ "GOOD" != "$i" ] && FLAG=1
        SMART="$SMART $i" 
      done      
    	
      if [ "$FLAG" == "0" ]; then
            	echo OK: $SMART 
            	exit 0
    	else
            	echo ERROR: $SMART
            	exit 2
    	fi 

# -> VOLUME Status ---------------------------------------------------------------
elif [ "$strCheck" == "volumes" ]; then
      VOLNUM=$(snmpget -v1 -c $strCommunity -mALL "$strHostname" .1.3.6.1.4.1.24681.1.2.16.0 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
     	i=1
      while [ $i -le $VOLNUM ]
      do
        raid_status[$i]=$(snmpget -v1 -c $strCommunity -mALL "$strHostname" .1.3.6.1.4.1.24681.1.2.17.1.6.$i | awk '{print $4, $5, $6}' | sed 's/^"\(.*\)"/\1/')
        let i=i+1
      done

      FLAG=0
      STATUS="RAID-Status: "
      for i in ${raid_status[@]}
      do
        [ "Ready" != "$i" ] && FLAG=1
        [ "Rebuilding" == "$i" ] && FLAG=2
        STATUS="$STATUS $i" 
      done      
    	
      if [ "$FLAG" == "0" ]; then
            	echo OK: $STATUS 
            	exit 0
    	elif [ "$FLAG" == "2" ]; then
            	echo "WARNING: "$STATUS
            	exit 1
    	else
            	echo CRITICAL: $STATUS
            	exit 2
    	fi 
          	
# -> FAN Status ----------------------------------------------------------------
elif [ "$strCheck" == "fan" ]; then
      FANNUM=$(snmpget -v1 -c $strCommunity -mALL "$strHostname" .1.3.6.1.4.1.24681.1.2.14.0 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
      i=1
      while [ $i -le $FANNUM ]
      do
        FAN[$i]=$(snmpget -v1 -c $strCommunity -mALL "$strHostname" .1.3.6.1.4.1.24681.1.2.15.1.3.$i | awk '{print $4}' | sed 's/^"\(.*\)/\1/')
        let i=i+1
      done

      FLAG=0
      RPM="RPM: "
      for i in ${FAN[@]}
      do
        [ "$i" -gt "2500" ] && FLAG=3
        [ "$i" -le "2500" ] && FLAG=2
        [ "$i" -le "2000" ] && FLAG=1     
        RPM="$RPM $i" 
      done      
    	
      if [ "$FLAG" == "1" ]; then
            	echo OK: $RPM 
            	exit 0
    	elif [ "$FLAG" == "2" ]; then
            	echo "WARNING: "$RPM
            	exit 1
    	else
            	echo CRITICAL: $RPM
            	exit 2
    	fi 

# -> HDD TEMP ------------------------------------------------------------------
elif [ "$strCheck" == "hdtemp" ]; then
      HDNUM=$(snmpget -v1 -c $strCommunity -mALL "$strHostname" .1.3.6.1.4.1.24681.1.2.10.0 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
      i=1
      while [ $i -le $HDNUM ]
      do
        HD[$i]=$(snmpget -v1 -c $strCommunity -mALL "$strHostname" .1.3.6.1.4.1.24681.1.2.11.1.3.$i | awk '{print $4}' | cut -c2-3)
        let i=i+1
      done

      FLAG=0
      TEMP="HD-TEMP in C: "
      for i in ${HD[@]}
      do
        [ "$i" -ge "50" ] && FLAG=3
        [ "$i" -le "40" ] && FLAG=2
        [ "$i" -le "30" ] && FLAG=1     
        TEMP="$TEMP $i" 
      done      
    	
      if [ "$FLAG" == "1" ]; then
            	echo OK: $TEMP 
            	exit 0
    	elif [ "$FLAG" == "2" ]; then
            	echo "WARNING: "$TEMP
            	exit 1
    	else
            	echo CRITICAL: $TEMP
            	exit 2
    	fi  

# -> CPU-TEMP ------------------------------------------------------------------
elif [ "$strCheck" == "cputemp" ]; then
    	TEMP=$(snmpget -v1 -c $strCommunity -mALL $strHostname .1.3.6.1.4.1.24681.1.2.5.0 | awk '{print $4}' | cut -c2-3)
     	strOutput="CPU-Temp: $[TEMP]C|'Temp C'=$[TEMP]C;42;45"

         	if [ $TEMP -ge "45" ]; then
                 	echo "CRITICAL: "$strOutput
                 	exit 2
         	fi
         	if [ $TEMP -ge "42" ]; then
                 	echo "WARNING: "$strOutput
                 	exit 1
         	fi
         	echo "OK: "$strOutput
         	exit 0

# -> SYS-TEMP ------------------------------------------------------------------
elif [ "$strCheck" == "systemp" ]; then
    	TEMP=$(snmpget -v1 -c $strCommunity -mALL $strHostname .1.3.6.1.4.1.24681.1.2.6.0 | awk '{print $4}' | cut -c2-3)
     	strOutput="SYS-Temp: $[TEMP]C|'Temp C'=$[TEMP]C;40;45"

         	if [ $TEMP -ge "45" ]; then
                 	echo "CRITICAL: "$strOutput
                 	exit 2
         	fi
         	if [ $TEMP -ge "42" ]; then
                 	echo "WARNING: "$strOutput
                 	exit 1
         	fi
         	echo "OK: "$strOutput
         	exit 0

# -> RAM-USAGE -----------------------------------------------------------------
elif [ "$strCheck" == "ramuse" ]; then
    	ramtot=$(snmpget -v1 -c $strCommunity -mALL $strHostname .1.3.6.1.4.1.24681.1.2.2.0 | awk '{print $4}' | sed 's/.\(.*\)/\1/')
    	ramfree=$(snmpget -v1 -c $strCommunity -mALL $strHostname .1.3.6.1.4.1.24681.1.2.3.0 | awk '{print $4}' | sed 's/.\(.*\)/\1/')
    	ramtot=$(echo "scale=0; $ramtot" | bc -l  |  sed 's/\(.*\).../\1/')
    	ramfree=$(echo "scale=0; $ramfree" | bc -l  |  sed 's/\(.*\).../\1/')
    	let "PERC=(100-($ramfree*100)/$ramtot)"    	
      strOutput="RAM: $[PERC]%|'RAM'=$[PERC]%;80;90;0;100"
    	if [ $PERC -ge "90" ]; then
      	echo "CRITICAL: "$strOutput
      	exit 2
    	fi
    	if [ $PERC -ge "80" ]; then
      	echo "WARNING: "$strOutput
      	exit 1
    	fi
      	echo "OK: "$strOutput
      	exit 0

# -> ---------------------------------------------------------------------------

else
    	echo -e "\nnon existing check!" && exit "3"
fi
exit 0