#!/bin/bash

set -e

function show_help {
    echo -e \
"This script install prerequisites to setup a Kubernetes cluster
through \`kubeadm\` utility. We use Docker as the container runtime.

Usage: ./00-prerequisites.sh [--version=KUBE_VERSION] [--sgx]
Parameters:

    --version  Selects the Kubernetes version, e.g., --version=1.19.0.
               IMPORTANT! Specify the full version number, including the
               patch version: 1.19.0, 1.20.3...
               Defaults to the latest available.
    --sgx      Installs Intel SGX driver in the node.
               Defaults to not install.
    -v         Verbose mode.
    -h         Show this message and exit.
"
}

# TODO: Switch to containerd.

# Parse parameters.
KUBE_VERSION=""
SGX=0

if [[ $# == 0 ]]; then
    show_help
    exit 0
fi

while (( "$#" )); do
    arg=$1

    case "$arg" in

        -v)
            set -x
            shift
            ;;

        -h)
            show_help
            exit 0
            shift
            ;;

        --sgx)
            SGX=1
            shift
            ;;

        --version=*)
            KUBE_VERSION="=${1#*=}-00"
            shift
            ;;

        *)
            echo "ERROR: Unrecognized parameter '$1'"
            exit 1
    esac
done

# Install Docker CE
apt-get update \
    && apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update \
    && apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

systemctl daemon-reload
systemctl restart docker

# Install kubeadm, kubectl and kubelet.
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-$(lsb_release -cs) main
EOF
apt-get update
apt-get install -y kubelet${KUBE_VERSION} kubeadm${KUBE_VERSION} kubectl${KUBE_VERSION}
apt-mark hold kubelet kubeadm kubectl

# Install SGX driver. Utility script taken from Scontain [1].
# [1] https://sconedocs.github.io/sgxinstall/
if [[ "$SGX" == 1 ]]; then
    curl -fsSL https://raw.githubusercontent.com/scontain/SH/master/install_sgx_driver.sh \
        | bash -s - install --auto --dkms -p metrics -p page0 -p version
fi
