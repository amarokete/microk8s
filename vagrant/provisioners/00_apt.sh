#!/bin/bash

set -eo pipefail

# https://packages.ubuntu.com/bionic-backports/cockpit
COCKPIT_VERSION="${COCKPIT_VERSION:-187-1}"
COCKPIT_UBUNTU_VERSION="${COCKPIT_UBUNTU_VERSION:-18.04.1}"

# Add Git PPA key
# shellcheck disable=SC2002
cat /vagrant/vagrant/keys/git.key | sudo apt-key add - > /dev/null

# Add Git source
echo 'deb [arch=amd64] http://ppa.launchpad.net/git-core/ppa/ubuntu bionic main' | sudo tee /etc/apt/sources.list.d/git.list > /dev/null

# Don't download translations
echo 'Acquire::Languages "none";' | sudo tee /etc/apt/apt.conf.d/99languages > /dev/null

# We don't want Cockpit to start after install, so mask the service
sudo ln -s /dev/null /etc/systemd/system/cockpit.service

# Update repositories and upgrade existing packages
sudo apt-get update
sudo apt-get upgrade -y

# Install new packages
sudo apt-get install -y \
  alien \
  git \
  socat \
  wget \
  "cockpit=${COCKPIT_VERSION}~ubuntu${COCKPIT_UBUNTU_VERSION}" \
  "cockpit-docker=${COCKPIT_VERSION}~ubuntu${COCKPIT_UBUNTU_VERSION}"
