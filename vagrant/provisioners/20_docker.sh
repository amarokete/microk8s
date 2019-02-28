#!/bin/bash

set -e

# Add Vagrant user to docker group
sudo usermod -aG docker vagrant

# Cockpit connects to /var/run/docker.sock, so we must pipe to it from Snap's Docker socket
sudo tee /etc/systemd/system/socat.service <<-EOF > /dev/null
[Unit]
Description=Multipurpose relay
Documentation=http://manpages.ubuntu.com/manpages/bionic/man1/socat.1.html
After=snap.microk8s.daemon-docker.service

[Service]
User=root
Group=root
ExecStart=/usr/bin/socat UNIX-LISTEN:/var/run/docker.sock,user=0,group=0,mode=0660,fork,unlink-early UNIX-CLIENT:/var/snap/microk8s/current/docker.sock
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable socat.service
sudo service socat start
