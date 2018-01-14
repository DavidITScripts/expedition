# expedition
Expedition - Automate your enumeration

Designed and created by DavidIT
This script pulls data from CSVs created by running nmap through msf,

and does a lot of cool stuff with it:

1.Sorts ip and port info into easily re-used lists
2.Creates a directory structure for each IP in the csv
3.Runs enumeration tools based on the ports found on each ip
4.Saves results of said tools to the aforementioned directories

Usage:

1. export your nmap scan from msfdb
2. create a project folder
3. Run the script
4. Go for a walk, drink some water(this step takes a while depending on what is running and number of hosts)

Usage: 
root@kali: expedition.sh /path/to/projectfolder /path/to/chosenfilename.csv

Note:
Feel free to reconfigure as you wish; 
it should not be hard to add/remove/tweak programs in this script. 
