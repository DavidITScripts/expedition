#!/bin/bash

#Expedition post-scan enumeration script  

GREEN='\033[0;32m' #green
RED='\033[0;31m' # red
CYAN='\033[0;36m' # for cyan header
NC='\033[0m' # no color

: 'Designed and created by DavidIT.

This script pulls data from CSVs created by running nmap through msf,
and does a lot of cool stuff with it:

1.Sorts ip and port info into easily re-used lists 
2.Creates a directory structure for each IP in the csv 
3.Runs enumeration tools based on the ports found on each ip 
4.Saves results of said tools to the aforementioned directories

Usage:

export your nmap scan from msfdb
create a project folder
Run the script
Go for a walk, drink some water(this step could take a while)

Usage: 
root@kali: expedition.sh /path/to/projectfolder /path/to/exportedfile.csv

Note: Feel free to reconfigure as you wish; it should not be hard to add/remove/tweak programs in this script.

'

PROJECT=$1
CSV=$2
echo $PROJECT
echo $CSV
echo ''
if [ -z "$*" ];
then 
	echo Expedition post scan script
	echo ''
	echo Usage:
	echo @:$PROJECT/expedition.sh /path/to/projectfolder /path/to/exportedfile.csv
exit
fi
GREEN='\033[0;32m' #green
RED='\033[0;31m' # red
CYAN='\033[0;36m' # for cyan header
NC='\033[0m' # no color

echo -e ${CYAN}Expedition \"Kitchen Sink\" post scan automation by DavidITScripts${NC}
echo ''
echo This script pulls port info from an msfdb CSV and builds project structure/lists
echo After that, it runs a suite of enumeration tools including:
echo - gobuster for both port 80 and 443\(common.txt\)
echo - Nikto on port 80 and 443
echo - sslscan on 443
echo - snmpwalk on 161
echo - Enum4linux wherever port 137,139, or 445 are open
echo - Finally, Eyewitness\(takes screenshots of all websites found by gobuster\)
echo ''
echo If you don\'t want to run certain programs, just comment them out in the script.
echo threads are set to default, you may need to adjust that.
echo ''
echo -e ${RED}Creator not responsible for blacklisting${NC}
echo ''
echo this might take a while\; you can find different versions of this script at github.com
read -n 1 -s -r -p "Press any key to continue"
echo ''
echo -e ${GREEN}Building lists first:${NC}
cat $CSV | grep -v 'host' | cut -d'"' -f2,4 --output-delimiter=':' > $PROJECT/browsable.txt
cat $CSV | grep -v 'host' | cut -d'"' -f2,4 --output-delimiter=' ' > $PROJECT/space.txt
cat $CSV | grep -v 'host' | cut -d'"' -f2| sort -u > $PROJECT/ips.txt
cat $CSV | grep -v 'host' | cut -d'"' -f4 > $PROJECT/ports.txt

#If the port exists, make a file for it.

if grep -q "80" $PROJECT/browsable.txt
then
	grep -w "80" $PROJECT/browsable.txt  | tee -a $PROJECT/80.txt   $PROJECT/80_443.txt      >/dev/null
fi

if grep -q "443" $PROJECT/browsable.txt
then
		grep -w "443" $PROJECT/browsable.txt | tee -a $PROJECT/443.txt  $PROJECT/80_443.txt      >/dev/null0
fi


if grep -q "137" $PROJECT/browsable.txt
then
	grep -w "137" $PROJECT/browsable.txt | tee -a $PROJECT/137.txt  $PROJECT/137_139_445.txt >/dev/null
fi

if grep -q "139" $PROJECT/browsable.txt
then
	grep -w "139" $PROJECT/browsable.txt | tee -a $PROJECT/139.txt  $PROJECT/137_139_445.txt >/dev/null
fi

if grep -q "445" $PROJECT/browsable.txt
then
	grep -w "445" $PROJECT/browsable.txt | tee -a 445.txt  $PROJECT/137_139_445.txt >/dev/null
fi

if grep -q "161" $PROJECT/browsable.txt
then
	grep -w "161" $PROJECT/browsable.txt | tee -a $PROJECT/161.txt                  >/dev/null
fi


echo ''

echo -e ${GREEN}Creating folders:${NC}
for ip in $(cat $PROJECT/ips.txt);do mkdir -p $ip && \
cat browsable.txt|grep $ip > $PROJECT/$ip/openports;
done
echo ''

#gobuster
if [ -e $PROJECT/80.txt ]
then
	for http in $(cat $PROJECT/80.txt | cut -d ':' -f1); do 

	echo -e ${CYAN}Running Gobuster\(common.txt\) on $http\:80 ${NC}
	gobuster -u http://$http \
  	-w /usr/share/seclists/Discovery/Web_Content/common.txt \
  	-s '200,204,301,307,403,500' -e | grep 'Status' | tee -a $PROJECT/$http/gobuster80.txt $PROJECT/$http/expedition.txt
  	grep 'Status: 200' $PROJECT/$http/gobuster80.txt >> $PROJECT/foundsites.txt
	done
fi

if [ -e $PROJECT/443.txt ]
	then
		for https in $(cat $PROJECT/443.txt | cut -d ':' -f1); do 
		echo -e ${CYAN}Running Gobuster\(common.txt\) on $https\:443 ${NC}
		gobuster -u https://$https \
  		-w /usr/share/seclists/Discovery/Web_Content/common.txt \
  		-s '200,204,301,307,403,500' -e | grep 'Status' | tee -a $PROJECT/$https/gobuster443.txt $PROJECT/$https/expedition.txt 
  		grep 'Status: 200' $PROJECT/$https/gobuster443.txt >> $PROJECT/foundsites.txt 
	done
fi

#Nikto

if [ -e $PROJECT/80.txt ]
then
	echo -e ${GREEN}Running Nikto on 80${NC}
	for ip in $(cat $PROJECT/80.txt | cut -d ':' -f1); do
	echo -e ${CYAN}Running Nikto on http://$ip${NC}
	nikto -h http://$ip tee -a $PROJECT/$ip/nikto80.txt $PROJECT/$ip/expedition.txt
	done
fi

if [ -e $PROJECT/443.txt ]
then
	echo -e ${GREEN}Running Nikto on 443${NC}
	for ip in $(cat $PROJECT/443.txt | cut -d ':' -f1); do
	echo -e ${CYAN}Running Nikto on https://$ip${NC}
	nikto -h https://$ip | tee -a $PROJECT/$ip/nikto443.txt $PROJECT/$ip/expedition.txt
	done
fi

#sslscan
if [ -e $PROJECT/443.txt ]
then
	echo -e ${GREEN}Running SSLScan on all port 443 addresses${NC}
	for ssl in $(cat $PROJECT/443.txt | cut -d ':' -f1); do
	echo -e ${CYAN}running SSLScan on $ssl${NC}
	sslscan --targets=$PROJECT/443.txt | tee -a $PROJECT/$ssl/sslscan.txt $PROJECT/expedition.txt
	done
fi

#snmpwalk

if [ -e $PROJECT/161.txt ]
then
	echo -e ${GREEN}Running snmpwalk\(public string\ on port 161)
	for snmp in cat($PROJECT/161.txt | cut -d ':' -f1); do
	echo -e ${CYAN}Running snmpwalk on $snmp${NC}
	snmpwalk -c public $snmp | tee -a  $PROJECT/$snmp/snmp.txt $PROJECT/$snmp/expedition.txt
	done
fi

#enum4linux
if [ -e $PROJECT/137_139_445.txt ]
then
	echo -e ${GREEN}Running Enum4linux on ports 137,139,445
	for enum in cat($PROJECT/137_139_445.txt | cut -d ':' -f1); do
	echo -e ${CYAN}Running Enum4linux on $enum${NC}
	done
fi
#EyeWitness. Note, it's last because it asks to open a report at the end. 
#If you want to run in another order, add the --no-report option to this part
#or you will have to hit yes or no. to continue the script.
if [-e $PROJECT/foundsites.txt ]
then
	echo -e ${GREEN}Running eyewitness on all found\(http status 200\) sites${NC}
	echo ''
	echo -e ${RED}NOTE: This takes screenshots of all sites including false positives\!
	sleep 3
	cut -d' ' -f1 $PROJECT/foundsites.txt >> $PROJECT/foundwebsites.txt
	rm foundsites.txt
	eyewitness  -f $PROJECT/foundwebsites.txt -d $PROJECT/eyewitness --web --timeout 20
	done
fi
