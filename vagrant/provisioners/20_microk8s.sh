#!/bin/bash

set -eo pipefail

KUBE_DIR='/home/vagrant/.kube'
SNAP_DIR='/snap/bin'

mkdir -p "$KUBE_DIR"

# UFW is installed but not enabled, so we shouldn't need to do this
# sudo ufw allow in on cbr0
# sudo ufw allow out on cbr0

# Docker sets IP Tables FORWARD policy to DROP by default
sudo iptables -P FORWARD ACCEPT

echo '--iptables=false' | sudo tee -a /var/snap/microk8s/current/args/dockerd > /dev/null

# Write the Kubeconfig
"${SNAP_DIR}/microk8s.kubectl" config view --raw | tee "${KUBE_DIR}/config" > /dev/null

# Wait for API Server to come online before installing add-ons
"${SNAP_DIR}/microk8s.status" --wait-ready

# Enabling DNS restarts Kubelet, so it requires elevated privileges
sudo "${SNAP_DIR}/microk8s.enable" dns dashboard ingress storage
