#!/bin/bash

set -eB

shopt -s expand_aliases

alias wget='wget --prefer-family=IPv4 -q -P $TMP_DIR'

KUBECTX_VERSION="${KUBECTX_VERSION:-0.6.3}"
MICRO_VERSION="${MICRO_VERSION:-1.4.1}"

BIN_DIR='/usr/local/bin'
COMPLETIONS_DIR='/usr/share/bash-completion/completions'
KUBECTX_DIR='/home/vagrant/.kubectx'
TMP_DIR='/tmp'

# Install Micro
wget "https://github.com/zyedidia/micro/releases/download/v${MICRO_VERSION}/micro-${MICRO_VERSION}-linux64.tar.gz"
tar -C "$TMP_DIR" -xzf "${TMP_DIR}/micro-${MICRO_VERSION}-linux64.tar.gz"
sudo cp {"$TMP_DIR/micro-$MICRO_VERSION","$BIN_DIR"}/micro
sudo chmod +x "${BIN_DIR}/micro"

# Install KubeCTX
git clone https://github.com/ahmetb/kubectx.git "$KUBECTX_DIR"
git -C "$KUBECTX_DIR" checkout "tags/v${KUBECTX_VERSION}"
sudo ln -s {"$KUBECTX_DIR","$BIN_DIR"}/kubectx
sudo ln -s {"$KUBECTX_DIR","$BIN_DIR"}/kubens
sudo ln -s "${KUBECTX_DIR}/completion/kubectx.bash" "${COMPLETIONS_DIR}/kubectx"
sudo ln -s "${KUBECTX_DIR}/completion/kubens.bash" "${COMPLETIONS_DIR}/kubens"
sudo chmod +x "${BIN_DIR}/kubectx"
sudo chmod +x "${BIN_DIR}/kubens"
