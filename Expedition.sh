#!/bin/bash

#Expedition post-scan enumeration script  


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





#this section sets up the flag support
OPTS=`getopt -o hp:f: --long help,nonik,noeye,nossl,nosnmap,nogo,gothreads:,golist:,gostatus: -n 'parse-options' -- "$@"`

if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi


echo "$OPTS"
eval set -- "$OPTS"

#big fat list of variables
ipsorter='sort -n -u -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4'
GOLIST='/usr/share/seclists/Discovery/Web_Content/common.txt'
GOSTATUS='200,204,301,307,403,500' 
GOTHREADS='10'
GREEN='\033[0;32m' #green
RED='\033[0;31m' # red
CYAN='\033[0;36m' # for cyan header
NC='\033[0m' # no color
LINE="=========================================================================="

while true; do
  case "$1" in


    -p | --project ) PROJECT="$2"; shift; shift ;;
    -f | --file )    GNMAP="$2"; shift; shift ;;
	--gothreads ) GOTHREADS="$2"; shift; shift ;;
	--golist ) GOLIST="$2"; shift; shift ;;
	--gostatus ) GOSTATUS="$2"; shift; shift ;;
	-- ) GOSTATUS="$2"; shift; shift ;;
    -- ) shift; break ;;
    * ) break;;
  esac
done
clear
echo Project path: $PROJECT
echo gnmap file: $GNMAP
echo Default Gobuster threads: $GOTHREADS
echo Default Gobuster List: $GOLIST
echo Default Gobuster Status: $GOSTATUS




echo ''
if [ -z $PROJECT ]||[ -z $GNMAP ];

then 
	echo Expedition post scan script
	echo ''
	echo This script takes a .gnmap file and does the following:
	echo - Create a directory structure per ip found
	echo - Creates several handy lists, including a CSV for notes
	echo - After this, it gives you the option to run a number of post scan enumeration tools including:
	echo ''
	echo - Gobuster\(A directory scanner\)
	echo - Enum4linux
	echo - SSLScan
	echo - SNMPWalk
	echo - 'EyeWitness(Takes screenshots of open RDP/VNC ports, as well as all status 200 websites found by Gobuster)'
	echo - Nikto
	echo - 
	echo ''
	echo $LINE
	echo ''
	echo Required Flags\:
	echo ''
	echo '-f | File path'
	echo '-p | project path'
	echo ''
	echo Programs can be selected from within the script.
	echo ''
	echo ''
	echo $LINE
	echo ''
	echo Additional Parameters\:
	echo You can change some popular parameters for some of the automated programs\:
	echo '--gothreads | sets thread count for gobuster'
	echo '--golist    | sets gobuster wordlist'
	echo '--gostatus  | sets gobuster status search'
	echo  ''
	echo $LINE
	echo ''

exit
fi


echo -e ${CYAN}Expedition post scan automation by DavidITScripts${NC}
echo ''
echo This script pulls port info from a .gnmap and builds project structure/lists
echo After that, it runs a suite of enumeration tools including:
echo - gobuster for both port 80 and 443\(common.txt\)
echo - Nikto on port 80 and 443
echo - sslscan on 443
echo - snmpwalk on 161
echo - Enum4linux wherever port 137,139, or 445 are open
echo - Finally, Eyewitness\(takes screenshots of all websites found by gobuster\)
echo ''
echo If you don\'t want to run certain programs, check help for flags to disable them.
echo ''
echo -e ${RED}NOTE\:${NC}
echo For automations sake, both Nikto and Eyewitness bring up prompts.
echo ''
echo to turn off nikto prompts, set UPDATES=auto or no
echo for eyewitness, just write --no-reports in the script.
echo -e ${RED}Creator not responsible for blacklisting${NC}
echo ''
echo this might take a while\; you can find different versions of this script at github.com
read -n 1 -s -r -p "Press any key to continue"
echo ''
echo -e ${GREEN}Building lists first:${NC}



#MENU HERE
options[0]="Gobuster"
options[1]="EyeWitness"
options[2]="SSLScan"
options[3]="SNMPWalk"
options[4]="Enum4Linux"
options[5]="Nikto"



#Actions to take based on selection
function ACTIONS {
    echo Enabled programs:
    if [[ ${choices[0]} ]]; then
        #Option 1 selected
        echo "Gobuster"
        GOBUSTER=true
    fi
    if [[ ${choices[1]} ]]; then
        #Option 2 selected
        echo "Eyewitness"
        EYEWITNESS=true
    fi
    if [[ ${choices[2]} ]]; then
        #Option 3 selected
        echo "SSLScan"
        SSLSCAN=true
    fi
    if [[ ${choices[3]} ]]; then
        #Option 4 selected
        echo "SNMPWalk"
        SNMPWALK=true
    fi
    if [[ ${choices[4]} ]]; then
        #Option 5 selected
        echo "Enum4linux"
        ENUM4LINUX=true
    fi
    if [[ ${choices[5]} ]]; then
        #Option 5 selected
        echo "Nikto"
        NIKTO=true
    fi
}

#Variables
ERROR=" "

#Clear screen for menu
clear

#Menu function
function MENU {
    echo "Expedition options"
    echo -e ${CYAN}Pick which programs you want to run${NC}
    for NUM in ${!options[@]}; do
        echo "[""${choices[NUM]:- }""]" $(( NUM+1 ))") ${options[NUM]}"
    done
    echo "$ERROR"
}

#Menu loop
while MENU && read -e -p "Select the desired options using their number (again to uncheck, ENTER when done): " -n1 SELECTION && [[ -n "$SELECTION" ]]; do
    clear
    if [[ "$SELECTION" == *[[:digit:]]* && $SELECTION -ge 1 && $SELECTION -le ${#options[@]} ]]; then
        (( SELECTION-- ))
        if [[ "${choices[SELECTION]}" == "+" ]]; then
            choices[SELECTION]=""
        else
            choices[SELECTION]="+"
        fi
            ERROR=" "
    else
        ERROR="Invalid option: $SELECTION"
    fi
done

ACTIONS

echo -e ${GREEN}Building lists first:${NC}
mkdir -p $PROJECT/raw_data
#can't have too many copies
cp $GNMAP $PROJECT/raw_data
cp $GNMAP $PROJECT
#creates a csv
cat $GNMAP |  grep '/open/' | sort -u | awk -F'Host: | \\(\\).+Ports: |, ' '{ printf "%s", $2; first=1; for(i=3; i < NR; i++) { split($i,a,"/"); if(a[2]=="open") { if(first==0) { print""; } printf ",%s,%s,%s",a[3],a[1],a[7]; first=0; } } print""; }' > expedition.csv

cat $GNMAP|grep "open/"|sed -e 's/Host: //g' -e 's/ (.*//g'|${ipsorter} > $PROJECT/raw_data/FoundHosts.txt

echo '[*] Building TCP Ports List...'
cat $GNMAP|grep "Ports:"|sed -e 's/^.*Ports: //g' -e 's;/, ;\n;g'|awk '!/udp|filtered/'|cut -d"/" -f 1|sort -n -u > $PROJECT/raw_data/TCP-Ports-List.txt



echo '[*] Building UDP Ports List...'
cat $GNMAP|grep "Ports:"|sed -e 's/^.*Ports: //g' -e 's;/, ;\n;g'|awk '!/tcp|filtered/'|cut -d"/" -f 1|sort -n -u > $PROJECT/raw_data/UDP-Ports-List.txt


if grep -q "tcp" $GNMAP
then
for i in `cat $PROJECT/raw_data/TCP-Ports-List.txt`;do
	   TCPPORT="$i"

        cat $GNMAP|grep " ${i}/open/tcp"|sed -e 's/Host: //g' -e 's/ (.*//g' -e "s/^/${i},TCP,/g"|${ipsorter} >> $PROJECT/raw_data/TCP-raw.txt
    done
    awk -F, '{print $3,$1}' OFS=, $PROJECT/raw_data/TCP-raw.txt | cut -d ',' -f1,2 --output-delimiter=':' >> $PROJECT/browsable.txt
    awk -F, '{print $3,$1}' OFS=, $PROJECT/raw_data/TCP-raw.txt | cut -d ',' -f1,2 --output-delimiter=' ' >> $PROJECT/space.txt
fi

if grep -q "udp" $GNMAP
then for i in `cat $PROJECT/raw_data/UDP-Ports-List.txt`;do
	UDPPORT="$i"


	cat $GNMAP|grep " ${i}/open/tcp"|sed -e 's/Host: //g' -e 's/ (.*//g' -e "s/^/${i},UDP,/g"|${ipsorter} >> $PROJECT/raw_data/UDP-raw.txt
    done
    awk -F, '{print $3,$1}' OFS=, $PROJECT/raw_data/UDP-raw.txt | cut -d ',' -f1,2 --output-delimiter=':' >> $PROJECT/browsable.txt
    awk -F, '{print $3,$1}' OFS=, $PROJECT/raw_data/UDP-raw.txt | cut -d ',' -f1,2 --output-delimiter=' ' >> $PROJECT/space.txt
fi


if grep -q "80" $PROJECT/browsable.txt
then
	grep -w "80" $PROJECT/browsable.txt  | tee -a $PROJECT/80.txt   $PROJECT/80_443.txt      >/dev/null
fi

if grep -q "443" $PROJECT/browsable.txt
then
		grep -w "443" $PROJECT/browsable.txt | tee -a $PROJECT/443.txt  $PROJECT/80_443.txt      >/dev/null0
fi

for ip in $(cat $PROJECT/80.txt); do
	echo http://$ip | tee -a $PROJECT/http_sites.txt $PROJECT/foundsites.txt >/dev/null
done

for ip in $(cat $PROJECT/443.txt); do
	echo https://$ip | tee -a $PROJECT/https_sites.txt $PROJECT/foundsites.txt >/dev/null
done

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

if grep -q "3389" $PROJECT/browsable.txt
then
	grep -w "3389" $PROJECT/browsable.txt | tee -a $PROJECT/3389.txt   $PROJECT/raw_data/WitnessTargets.txt               >/dev/null
fi

if grep -q "5900" $PROJECT/browsable.txt
then
	grep -w "5900" $PROJECT/browsable.txt | tee -a $PROJECT/5900.txt                 >/dev/null
fi

for address in $PROJECT/3389.txt;do
	echo rdp://$address >> $PROJECT/raw_data/WitnessTargets.txt
done

for address in $PROJECT/5900.txt;do
	echo vnc://$address >> $PROJECT/raw_data/WitnessTargets.txt
done



echo ''

echo -e ${GREEN}Creating folders:${NC}
for ip in $(cat $PROJECT/raw_data/FoundHosts.txt);do mkdir -p $PROJECT/$ip && \
cat $PROJECT/browsable.txt|grep $ip > $PROJECT/$ip/openports;
done
echo ''

#gobuster
if [ -e $PROJECT/80.txt ] && [ "$GOBUSTER" = true ];
then
	for http in $(cat $PROJECT/80.txt | cut -d ':' -f1); do 

	echo -e ${CYAN}Running Gobuster\(common.txt\) on $http\:80 ${NC}
	gobuster -u http://$http \
  	-w $GOLIST \ -t $GOTHREADS \
  	-s $GOSTATUS -e | grep 'Status' | tee -a $PROJECT/$http/gobuster80.txt $PROJECT/$http/expedition.txt
  	grep -v 'Status: 200' $PROJECT/$http/gobuster80.txt > $PROJECT/foundsites.txt
	done
fi

if [ -e $PROJECT/443.txt ] && [ "$GOBUSTER" = true ];
	then
		for https in $(cat $PROJECT/443.txt | cut -d ':' -f1); do 
		echo -e ${CYAN}Running Gobuster\(common.txt\) on $https\:443 ${NC}
		gobuster -u https://$https \
  		-w $GOLIST \ -t $GOTHREADS \
  		-s $GOSTATUS -e | grep 'Status' | tee -a $PROJECT/$https/gobuster443.txt $PROJECT/$https/expedition.txt 
  		grep 'Status: 200' $PROJECT/$https/gobuster443.txt >> $PROJECT/foundsites.txt 
	done
fi

if [ ! -f $PROJECT/80_443.txt ]  && [ "$GOBUSTER" = true ];
then
	echo -e ${RED}'Could not find any open ports on 80 or 443; skipping Gobuster'${NC}
done
fi




#Nikto

if [ -e $PROJECT/80.txt ] && [ "$NIKTO" = true ];
then
	echo -e ${GREEN}Running Nikto on 80${NC}
	for ip in $(cat $PROJECT/80.txt | cut -d ':' -f1); do
	echo -e ${CYAN}Running Nikto on http://$ip${NC}
	nikto -h http://$ip tee -a $PROJECT/$ip/nikto80.txt $PROJECT/$ip/expedition.txt
	done
fi

if [ -e $PROJECT/443.txt ]  && [ "$NIKTO" = true ];
then
	echo -e ${GREEN}Running Nikto on 443${NC}
	for ip in $(cat $PROJECT/443.txt | cut -d ':' -f1); do
	echo -e ${CYAN}Running Nikto on https://$ip${NC}
	nikto -h https://$ip | tee -a $PROJECT/$ip/nikto443.txt $PROJECT/$ip/expedition.txt
	done
fi

if [ ! -f $PROJECT/80_443.txt ]  && [ "$NIKTO" = true ];
then
	echo -e ${RED}'Could not find any open ports on 80 or 443; skipping Nikto'${NC}
done
fi



#sslscan
if [ -e $PROJECT/443.txt ]  && [ "$SSLSCAN" = true ];
then
	echo -e ${GREEN}Running SSLScan on all port 443 addresses${NC}
	for ssl in $(cat $PROJECT/443.txt | cut -d ':' -f1); do
	echo -e ${CYAN}running SSLScan on $ssl${NC}
	sslscan --targets=$PROJECT/443.txt | tee -a $PROJECT/$ssl/sslscan.txt $PROJECT/expedition.txt
done
fi

if [ ! -f $PROJECT/443.txt ]  && [ "$SSLSCAN" = true ];
then
	echo -e ${RED}'Could not find any open SSL ports for SSLSCAN; skipping.'${NC}
done
fi


#snmpwalk

if [ -e $PROJECT/161.txt ] && [ "$SNMPWALK" = true ];
then
	echo -e ${GREEN}Running snmpwalk\(public string\ on port 161\)
	for snmp in $(cat $PROJECT/161.txt | cut -d ':' -f1); do
	echo -e ${CYAN}Running snmpwalk on $snmp${NC}
	snmpwalk -c public $snmp | tee -a  $PROJECT/$snmp/snmp.txt $PROJECT/$snmp/expedition.txt
done
	echo -e ${RED}No SNMP ports found; skipping snmpwalk.${NC}
fi

if [ ! -f $PROJECT/161.txt ] && [ "$SNMPWALK" = true ];
then
	echo -e ${RED}'Could not find any open 161 ports; skipping SNMPWALK'${NC}
fi

#enum4linux
if [ -e $PROJECT/137_139_445.txt ] && [ "$ENUM4LINUX" = true ];
then
	echo -e ${GREEN}Running Enum4linux on ports 137,139,445
	for enum in $(cat $PROJECT/137_139_445.txt | cut -d ':' -f1 | sort -u); do
	echo -e ${CYAN}Running Enum4linux on $enum${NC}
	enum4linux $enum
	done
fi

if [ ! -f $PROJECT/137_139_445.txt ] && [ "$ENUM4LINUX" = true ];
then
	echo -e ${RED}'No applicable ports appear to be open for enum4linux; skipping.'${NC}
	done
fi


#EyeWitness. Note, it's last because it asks to open a report at the end. 
#If you want to run in another order, add the --no-report option to this part
#or you will have to hit yes or no. to continue the script.
if [[ -e $PROJECT/foundsites.txt && "$EYEWITNESS" = true ]];
then
	echo -e ${GREEN}Running eyewitness on all found\(http status 200\) sites${NC}
	echo ''
	echo -e ${RED}NOTE: This takes screenshots of all sites including false positives\!
	sleep 3
	cat $PROJECT/foundsites.txt >> $PROJECT/raw_data/WitnessTargets.txt
	eyewitness  --no-prompt -f $PROJECT/raw_data/WitnessTargets.txt -d $PROJECT/eyewitness --all-protocals --timeout 20

fi
