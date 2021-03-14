#!/bin/bash
# This is my attempt at some automation for the OpenStack testing
apt update
apt upgrade -y
echo Installing stuff from apt

echo "Grabbing down new config files (interfaces, openstack_user_config.yml, resolv.conf)"
wget -O ~/interfaces https://raw.githubusercontent.com/sean-perryman/openstack/main/infra1_interfaces
wget -O ~/openstack_user_config.yml https://raw.githubusercontent.com/sean-perryman/openstack/main/openstack_user_config.yml
wget -O ~/resolv.conf https://raw.githubusercontent.com/sean-perryman/openstack/main/resolv.conf

apt install -y ifupdown ifupdown-extra bridge-utils resolvconf build-essential git chrony openssh-server python3-dev lm-sensors
snap insatll bashtop

echo Disabling UFW
systemctl disable ufw

echo Stopping UFW
systemctl stop ufw

echo Moving Netplan files
mv /etc/netplan/* ~

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

echo Bootstrapping Ansible
/usr/bin/bash /opt/openstack-ansible/scripts/bootstrap-ansible.sh

echo Creating user_secrets.yml
/usr/bin/python3 /opt/openstack-ansible/scripts/pw-token-gen.py --file /etc/openstack_deploy/user_secrets.yml

cp ~/resolv.conf /etc/resolv.conf
cp ~/openstack_user_config.yml /etc/openstack_deploy
cp ~/interfaces /etc/network/interfaces

ping -c 4 google.com

echo Interfaces file
head /etc/network/interfaces

echo OpenStack User Config
head /etc/openstack_deploy/openstack_user_config.yml

echo Done!
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
echo "| Things that may still need to be done                                   |"
echo "| ----------------------------------------------------------------------- |"
echo "| Add yourself to visudo NOPASSWD                                         |"
echo "| /opt/openstack-ansible/playbooks/openstack-ansible setup-everything.yml |"
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"

read -p "Press [Enter] to reboot if everything looks good. Otherwise, CTRL + C to cancel."
reboot
