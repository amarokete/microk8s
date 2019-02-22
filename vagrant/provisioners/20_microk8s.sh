#!/bin/bash

set -e

# TODO: Use tee -a to append
# Set $DOCKER_HOST system-wide
sudo tee /etc/environment <<-EOF > /dev/null
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
DOCKER_HOST="unix:///var/snap/microk8s/current/docker.sock"
EOF

sudo snap alias microk8s.docker docker
sudo snap alias microk8s.kubectl kubectl

sudo microk8s.enable dns dashboard
