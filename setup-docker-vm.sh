#!/bin/bash

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    lsb-release \
    gnupg2 \
    software-properties-common \
    git

# Get Docker GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

# Get the Google GPG key
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# Get the Azure CLI GPG key
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null

# Setup the Docker repository
echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list

# Setup the Kubernetes repository
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list

# Setup the Azure CLI repository
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/azure-cli.list

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    kubectl \
    azure-cli
