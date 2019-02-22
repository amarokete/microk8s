#!/bin/bash

set -eo pipefail

# Don't download translations
echo 'Acquire::Languages "none";' | sudo tee /etc/apt/apt.conf.d/99languages > /dev/null

# Update repositories and upgrade existing packages
sudo apt-get update
sudo apt-get upgrade -y
