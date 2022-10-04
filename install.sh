#!/bin/bash

set -xe

systemctl enable docker
modprobe br_netfilter



cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF



cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

CNI_VERSION="v1.0.1"
CRICTL_VERSION="v1.24.3"
RELEASE_VERSION="v0.14.0"
DOWNLOAD_DIR=/opt/bin
RELEASE="v1.23.9"



mkdir -p /opt/cni/bin && chmod -R u+wx /opt/bin
mkdir -p /etc/systemd/system/kubelet.service.d
curl -sSL "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
curl -sSL --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet}

chmod +x {kubeadm,kubelet}
mv {kubeadm,kubelet} $DOWNLOAD_DIR/

systemctl enable --now kubelet && systemctl start kubelet
systemctl status kubelet

kubeadm join 192.168.1.61:6443 --token o9xx96.y6pavfnjt9m2b77p --discovery-token-ca-cert-hash sha256:539ea94db3638c8f9cad2a57d9f76dcaaa1896593c84f0720e980fea02fa450b

