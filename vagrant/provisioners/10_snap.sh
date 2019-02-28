#!/bin/bash

set -e

shopt -s expand_aliases

alias snap='sudo /usr/bin/snap'

KUBERNETES_VERSION="${KUBERNETES_VERSION:-1.13}"
KUBERNETES_CHANNEL="${KUBERNETES_CHANNEL:-stable}"

HELM_CHANNEL="${HELM_CHANNEL:-stable}"

snap install --classic --channel="${KUBERNETES_VERSION}/${KUBERNETES_CHANNEL}" microk8s
snap install --classic --channel="${KUBERNETES_VERSION}/${KUBERNETES_CHANNEL}" kubectl
snap install --classic --channel="$HELM_CHANNEL" helm

# Alias docker
snap alias microk8s.docker docker
