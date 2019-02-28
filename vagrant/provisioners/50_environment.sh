#!/bin/bash

set -e

sudo tee /etc/environment <<-EOF > /dev/null
PATH="/snap/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games"
EDITOR="/usr/local/bin/micro"
VISUAL="/usr/local/bin/micro"
DOCKER_HOST="unix:///var/snap/microk8s/current/docker.sock"
KUBECONFIG="/home/vagrant/.kube/config"
EOF
