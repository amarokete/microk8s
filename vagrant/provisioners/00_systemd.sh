#!/bin/bash

set -eo pipefail

# Disable UFW
sudo systemctl disable ufw.service
sudo service ufw stop

# Disable Linux Containers
sudo systemctl disable lxd.service
sudo systemctl disable lxcfs.service
sudo service lxd stop
sudo service lxcfs stop

# Disable Unattended Upgrades
echo 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean false' | sudo debconf-set-selections

# dpkg-reconfigure -f noninteractive doesn't want to work, so we'll just do it manually
sudo tee /etc/apt/apt.conf.d/20auto-upgrades <<-EOF > /dev/null
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

sudo systemctl disable unattended-upgrades.service
sudo service unattended-upgrades stop
