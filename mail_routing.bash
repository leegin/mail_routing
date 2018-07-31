#!/bin/bash
#Author : Leegin Bernads
#Version : 2.0.0
#This is the script that will automate the removal/addition of the servers in the outbound server.
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

#First of all we shall set the flags for spamming & routing.
mailrouting=no
spamming=no

#Get the IP address of the server.
HOST=$(hostname -i)

#Use the API to check the RBLs in which the server IP address is listed.
curl "<API you use to get the detals of the RBLs>" > /root/mail_routing_check

#Function to check if the server is already routed via outbound server. If yes then check the score and if it is 100% clean remove it from routing.
cleanip()
{
    	if [ -f /root/mail_routing ]
    	then
    	rm -rf /root/mail_routing
    	echo "[`date`] The IP address $HOST has been removed from outbound server." > /root/routing_removal.log
    	else
    	echo "[`date`] The IP address $HOST is not routed via Outbound server." >> /root/routing_removal.log
    	fi
}

#Function to check if the server IP is not blacklisted in spam tracking RBLs or else make sure that it is not routed.
blacklistedip()
{
#Get the RBLs in which IP address is listed and store them in a variable.
    Blacklists=$(awk -v RS='[,\n]' '{a=$0;print a}' OFS=, mail_routing_check | grep -Ev 'status|ip|score' | cut -d"[" -f2 | cut -d"]" -f1 | column -t | sed -e 's/^"//' -e 's/"$//')

#Compare each value in the variable with the names of RBLs which are safe to route.    	
	for i in $(echo $Blacklists);do
        if [[ $i = cbl.* || $i = spamhaus.* || $i = zen.* ]]
        then
#If the RBLs which are safe to route are found then set the mailrouting flag to 'yes'.
        mailrouting=yes
        echo "[`date`] The IP address has been blacklisted on $i and can be routed via the outbound server" >> /root/routing_removal.log
        else
#Incase if the RBLs in which the IP is listed match any of them then set the spamming flag to 'yes'.
        spamming=yes
		echo "[`date`] The IP address is blacklisted on $i and spamming should be fixed" >> /root/routing_removal.log
        fi
        done
#Now if the spamming flag goes 'yes', then the IP address is listed because of spamming and it shouldn't be routed via outbound.		
        if [ $spamming == yes ]
        then
        rm -rf /root/mail_routing
        echo "[`date`] Since the IP is listed on Spam Tracking RBLs it is not routed." >> /root/routing_removal.log
        else
#Suppose if the mailrouting flag goes 'yes', then the IP address is safe to be routed via the outbound server. Create the mail_routing file in this case.	
			if [[ $spamming == no && $mailrouting == yes ]]
			then
			touch /root/mail_routing
			echo "[`date`] The IP address has been routed via the outbound server" >> /root/routing_removal.log
			else
			echo "[`date`] No action required!" >> /root/routing_removal.log
			exit
			fi
        fi
}

#If the score of the IP address is 100, then use the functions and proceed accordinly.
if [ `cat mail_routing_check | grep -Po '"score":\K[^,^]+'| column -t` -eq 100 ]
then
	cleanip
else
	blacklistedip
fi
