#!/bin/bash
# Following checks if you're running as root or not
if [[ "$EUID" -ne 0 ]]; then
	echo "Please run with sudo or as root."
	exit 1
fi

ipcalcCheck=`type ipcalc 2>&1`
if [[ "$ipcalcCheck"  =~ "not found" ]]; then
	echo "ipcalc is required and not installed, testing for internet connection..."
	pingCheck=`ping -q -c 5 8.8.8.8 |grep "received" |awk '{print $4}'`
	if [[ $pingCheck -ge 3 ]]; then
		echo "Internet connection online, installing ipcalc..."
		apt update
		apt -y install ipcalc
	else
		echo "$pingCheck out of 5 ping attempts were successful."
		echo "Please connect to the internet and run apt-get install ipcalc."
		exit 1
	fi
fi

lcInterface=`ifconfig |grep "UP" |awk '{print $1}' |awk -F: '{print $1}' |grep en`
networkConfig=`ls /etc/netplan/*.yaml`
hostsFile="/etc/hosts"
unboundConfig="/etc/unbound/unbound.conf"
netdataConfig="/etc/netdata/netdata.conf"
nginxConfigDir="/etc/nginx/"
lcOldIP=`cat $hostsFile |grep lancache-eth |awk '{print $1}'`
lcOldGateway=`cat $networkConfig |grep "gateway4" |awk '{print $2}'`
lcOldNetmask=`ifconfig $lcInterface |grep netmask |awk '{print $4}'`
lcOldCIDR=`ipcalc $lcOldIP $lcOldNetmask |grep Netmask |awk '{print $4}'`

##This for some reason can't be passed to sed properly.
##If it can be fixed, we can remove the ipcalc dependency
#lcOldCIDR=`/bin/ip -4 addr show $lcInterface |grep -oP "(?<=inet ).*(?=br)" |awk -F\/ '{print $2}' |head -n1`

echo "Changing interface configuration from static to DHCP..."
sed -i "s/addresses\:/\#addresses\:/g" $networkConfig
sed -i "s/nameservers\:/\#nameservers\:/g" $networkConfig
sed -i "s/gateway4\:/\#gateway4\:/g" $networkConfig
sed -i "s/dhcp4\: no/dhcp4\: yes/g" $networkConfig

echo "Applying configuration..."
netplan apply

echo "Getting new IP Address from DHCP..."
dhclient $lcInterface

lcServices=(arena apple blizzard hirez gog glyph microsoft origin riot steam sony enmasse wargaming uplay zenimax digitalextremes pearlabyss)
lcIPAddress=`ifconfig $lcInterface |grep -w "inet" |awk '{print $2}'`
lcIP3Octects=`echo $lcIPAddress |awk -F\. '{print $1"."$2"."$3"."}'`
lcIPOctet4=`echo $lcIPAddress |awk -F\. '{print $4}'`
lcGateway=`ip route get 8.8.8.8 |awk '{print $3}' |head -n1`
lcNetmask=`ifconfig $lcInterface |grep netmask |awk '{print $4}'`
lcCIDR=`ipcalc $lcIPAddress $lcNetmask |grep Netmask |awk '{print $4}'`

##This for some reason can't be passed to sed properly.
##If it can be fixed, we can remove the ipcalc dependency
#lcCIDR=`/bin/ip -4 addr show $lcInterface |grep -oP "(?<=inet ).*(?=br)" |awk -F\/ '{print $2}' |head -n1`

echo "Stopping Lancache services..."
echo "Stopping nginx..."
systemctl stop nginx
echo "Stopping unbound..."
systemctl stop unbound
echo "Stopping netdata..."
systemctl stop netdata

echo "Changing primary IP in hosts file..."
sed -i "s/$lcOldIP/$lcIPAddress/g" $hostsFile
echo "Changing primary IP in unbound config..."
sed -i "s/$lcOldIP/$lcIPAddress/g" $unboundConfig
echo "Changing primary IP in netdata config..."
sed -i "s/$lcOldIP/$lcIPAddress/g" $netdataConfig
echo "Changing primary IP in network config..."
sed -i "s/${lcOldIP}\/${lcOldCIDR}/${lcIPAddress}\/${lcCIDR}/g" $networkConfig
echo "Changing Default Gateway..."
sed -i "s/$lcOldGateway/$lcGateway/g" $networkConfig

echo "Editing nginx configs..."
nginxLocations=`grep -i -r $lcOldIP $nginxConfigDir |awk -F\: '{print $1}'`
for i in $nginxLocations
do
	sed -i "s/$lcOldIP/$lcIPAddress/g" $i
done

echo "Editing service addresses..."
((lcIPOctet4++))
for i in ${lcServices[@]}
do
	lcServiceOldIP=`cat $hostsFile |grep "lancache-$i" |grep -v "backend" |awk '{print $1}'`
	sed -i "s/${lcServiceOldIP}/${lcIP3Octects}${lcIPOctet4}/g" $hostsFile
	sed -i "s/${lcServiceOldIP}\/${lcOldCIDR}/${lcIP3Octects}${lcIPOctet4}\/${lcCIDR}/g" $networkConfig
	((lcIPOctet4++))
	unset lcServiceOldIP
done

echo "Changing interface configuration DHCP to static..."
sed -i "s/\#addresses\:/addresses\:/g" $networkConfig
sed -i "s/\#nameservers\:/nameservers\:/g" $networkConfig
sed -i "s/\#gateway4\:/gateway4\:/g" $networkConfig
sed -i "s/dhcp4\: yes/dhcp4\: no/g" $networkConfig

echo "Applying network configuration..."
netplan apply

echo "Waiting 5 seconds for netplan to finish..."
sleep 5

echo "Starting Lancache services..."
echo "Starting nginx..."
systemctl start nginx
echo "Starting unbound..."
systemctl start unbound
echo "Starting netdata..."
systemctl start netdata
netplan apply

echo "Done! Reboot system just in case."