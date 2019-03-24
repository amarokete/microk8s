# microk8s

> :rocket: Kubernetes on Ubuntu with microk8s.

This is a Vagrant environment for developing on Kubernetes.

## Features

  - [microk8s](https://github.com/ubuntu/microk8s)
  - [Helm](https://github.com/helm/helm)
  - [Cockpit](https://github.com/cockpit-project/cockpit)
  - [kubectx](https://github.com/ahmetb/kubectx)

## Installation

Review the Vagrantfile and provisioning scripts first. When you're ready, clone the repository and
run `vagrant up` in it.

I recommend also installing the [vagrant-vbguest](https://github.com/dotless-de/vagrant-vbguest)
plugin.

## Examples

  - [HTTP Ingress](./examples/HTTP_Ingress)
  - [MongoDB Replica Set](./examples/MongoDB_Replica_Set)

## TODO

  1. More examples!
