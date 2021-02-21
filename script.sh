#!/bin/bash
echo "[Note] : For out_of_scope domains please add any another agruments"
echo "Usage: ./script.sh <domain> <any arg> "

rm final.txt
rm third-level.txt
rm probed.txt
rm scanned.txt
rm -r thirdlevels
rm -r scans
rm -r eyewitness

if [ $# -gt 2 ];
then
	echo "[Usage : ./script.sh <domain>]"
	echo "Example : ./script.sh yahoo.com"
	exit 1
fi

if [ ! -d "thirdlevels" ];
then
	mkdir thirdlevels
fi

if [ ! -d "scans" ];
then
	mkdir scans	
fi

if [ ! -d "eyewitness" ];
then
	mkdir eyewitness
fi

pwd=$(pwd)


echo "<<<<<<< Gathering subdomains with sublist3r >>>>>>"

sublist3r -d $1 -o final.txt

echo $1 >> final.txt

echo "<<<<<< Compiling third-level domains >>>>>>"
cat final.txt | grep -Po "(\w+\.\w+.\w+)$" | sort -u >> third-level.txt

echo "<<<<<< Gathering full third-level domains with sublist3r >>>>>>"
for domain in $(cat third-level.txt); 
do
	 sublist3r -d $domain -o thirdlevels/$domain.txt;
	 cat thirdlevels/$domain.txt | sort -u >> final.txt
done

if [ $# -eq 2 ];
then 
	if [ ! -d "out_of_scope.txt" ];
	then
		echo "please make a file out_of_scope.txt and add out_of_scope domains into it."
	fi
	
	# please add a out_of_domain.txt
	for out_of_scope in $(cat out_of_scope.txt);
	do
		echo "<<<<< removing out_of_scope domains >>>>>"
		cat final.txt | grep -v $out_of_scope | sort -u > probed.txt;
	done
	
	echo "<<<<< Probing for alive third-levels >>>>>"
	cat probed.txt | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ":443" | sort -u > probed.txt
	
else
	echo "<<<<< Probing for alive third-levels >>>>>"
	cat final.txt | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ":443" | sort -u > probed.txt
fi

echo "<<<<< Scanning for open ports >>>>>"
nmap -iL probed.txt -T4 -oA scans/scanned.txt

#echo "<<<<< Running EyeWitness >>>>>"
python3 /root/toolsss/EyeWitness/Python/EyeWitness.py -f $pwd/probed.txt --timeout 20 > eyewitness/
#mv /usr/share/eyewitness/$1 eyewitness/$1
	
