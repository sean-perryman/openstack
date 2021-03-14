#!/bin/bash
# This is my attempt at some automation for the OpenStack testing
apt update
apt upgrade -y
echo Installing stuff from apt

echo "Grabbing down new config files (interfaces, openstack_user_config.yml, resolv.conf)"
wget -O ~/interfaces https://raw.githubusercontent.com/sean-perryman/openstack/main/compute1_interfaces
wget -O ~/resolv.conf https://raw.githubusercontent.com/sean-perryman/openstack/main/resolv.conf

apt install -y ifupdown ifupdown-extra bridge-utils debootstrap openssh-server tcpdump vlan python3 resolvconf

echo Disabling UFW
systemctl disable ufw

echo Stopping UFW
systemctl stop ufw

echo Removing Netplan files
rm -rf /etc/netplan/*

echo Setting timezone and enabling NTP
timedatectl set-ntp true
timedatectl set-timezone "America/New_York"

echo Generating SSH keys
ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""

echo Bringing in existing authorized_keys
cp /home/cloudy/.ssh/authorized_keys ~/.ssh/

echo Adding new public key to existing authorized_keys
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

echo Copying over .ssh folder to /home/cloudy
cp -R ~/.ssh/* /home/cloudy/.ssh/

echo Fixing .ssh perms for Cloudy
chown -R cloudy:cloudy /home/cloudy/

cp ~/resolv.conf /etc/resolv.conf
cp ~/interfaces /etc/network/interfaces

ping -c 4 google.com

echo Interfaces file
head /etc/network/interfaces

echo Done!
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
echo "| Things that may still need to be done                                   |"
echo "| ----------------------------------------------------------------------- |"
echo "| Add yourself to visudo NOPASSWD                                         |"
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"

read -p "Press [Enter] to reboot if everything looks good. Otherwise, CTRL + C to cancel."
reboot
