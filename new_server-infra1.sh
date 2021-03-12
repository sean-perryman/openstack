#!/bin/bash
# This is my attempt at some automation for the OpenStack testing
apt update > /dev/null
apt upgrade -y > /dev/null
echo Installing stuff from apt
apt install -y ifupdown ifupdown-extra bridge-utils resolvconf build-essential git chrony openssh-server python3-dev

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

echo Cloning OpenStack from git
git clone -b 22.0.1 https://opendev.org/openstack/openstack-ansible /opt/openstack-ansible

echo Copying over openstack_deploy directory
cp -R /opt/openstack-ansible/etc/openstack_deploy/ /etc/

echo Creating user_secrets.yml
python3 /opt/openstack-ansible/scripts/pw-token-gen.py --file /etc/openstack_deploy/user_secrets.yml

echo "Grabbing down new config files (interfaces, openstack_user_config.yml, resolv.conf)"
wget -O /etc/network/interfaces https://raw.githubusercontent.com/sean-perryman/openstack/main/infra1_interfaces
wget -O /etc/openstack_deploy/openstack_user_config.yml https://raw.githubusercontent.com/sean-perryman/openstack/main/openstack_user_config.yml
wget -O /etc/resolv.conf https://raw.githubusercontent.com/sean-perryman/openstack/main/resolv.conf

echo Done!
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
echo "| Things that may still need to be done                                   |"
echo "| ----------------------------------------------------------------------- |"
echo "| Add yourself to visudo NOPASSWD                                         |"
echo "| /opt/openstack-ansible/scripts/bootstrap-ansible.sh                     |"
echo "| /opt/openstack-ansible/playbooks/openstack-ansible setup-everything.yml |"
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"

reboot
