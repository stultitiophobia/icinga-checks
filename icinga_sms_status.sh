#!/bin/bash
processname=icinga
icingacontacts=/usr/local/icinga/etc/buerokompetenz/kontakte.cfg
statuscontacts=/var/spool/sms/icinga_sms_contacts
smsheader=/var/spool/sms/sms_status_header
smsbody=/var/spool/sms/sms_status_body
smsoutdir=/var/spool/sms/outgoing
timestamp=$(date +"%d.%m.%Y")

cat $icingacontacts | grep pager | grep +4915222511... -o > $statuscontacts

if ps -C $processname | grep -v grep | grep $processname > /dev/null
then 
	echo "Monitoring status:"	> $smsbody
	echo "---------------------"	>> $smsbody
	echo "GOOD"	>> $smsbody
	echo "---------------------"	>> $smsbody
	echo "(Y)"	>> $smsbody
else	
	echo "Monitoring status:"	> $smsbody
	echo "---------------------"	>> $smsbody
	echo "BAD"	>> $smsbody
	echo "---------------------"	>> $smsbody
	echo "(N)"	>> $smsbody
fi

mobiles=( `cat "$statuscontacts" `)
for mobile in "${mobiles[@]}"
do
	echo "To: $mobile" > $smsheader
	echo "Flash: yes" >> $smsheader
	echo "" >> $smsheader
	cat $smsheader $smsbody > $smsoutdir"/"$processname"-status_"$timestamp"_"$mobile"_#"$RANDOM
done

rm $smsbody
rm $smsheader
rm $statuscontacts
