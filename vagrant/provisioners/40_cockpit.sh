#!/bin/bash

set -e

COCKPIT_VERSION="${COCKPIT_VERSION:-187-1}"
COCKPIT_FEDORA_VERSION="${COCKPIT_FEDORA_VERSION:-29}"

# Download Cockpit Kubernetes RPM package
# https://pkgs.org/download/cockpit-kubernetes
wget \
  --quiet \
  --prefer-family='IPv4' \
  --directory-prefix='/tmp' \
  "http://download.fedoraproject.org/pub/fedora/linux/updates/${COCKPIT_FEDORA_VERSION}/Everything/x86_64/Packages/c/cockpit-kubernetes-${COCKPIT_VERSION}.fc${COCKPIT_FEDORA_VERSION}.x86_64.rpm"

# Install Cockpit Kubernetes package
# Until Kubectl ships with Debian/Ubuntu, you'll have to convert the Fedora package to use it
sudo alien -k -i "/tmp/cockpit-kubernetes-${COCKPIT_VERSION}.fc${COCKPIT_FEDORA_VERSION}.x86_64.rpm"

# Remove the mask and start the service
sudo systemctl unmask cockpit.service
sudo service cockpit start
