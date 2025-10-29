#!/bin/bash
# CentOS 9 - Container Host Setup (Docker/Kubernetes)
# Author: Savaş Enes Erateşli
# Purpose: CGroup v2, sysctl, modüller, swap disable
# --------------------------------------

LOGFILE="/var/log/container-host-setup.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "### ENABLE CGROUP V2 ###"
grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=1 systemd.legacy_systemd_cgroup_controller=0"

echo "### LOAD NECESSARY KERNEL MODULES ###"
cat <<EOF >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

echo "### SYSCTL SETTINGS FOR CONTAINERS ###"
cat <<EOF >/etc/sysctl.d/99-kubernetes.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
fs.file-max = 2097152
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 524288
vm.swappiness = 10
vm.overcommit_memory = 1
vm.max_map_count = 262144
EOF
sysctl --system

echo "### DISABLE SWAP ###"
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "### DOCKER CONFIGURATION (if installed) ###"
if command -v docker &> /dev/null; then
    mkdir -p /etc/docker
    cat <<EOF >/etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": { "max-size": "100m" },
  "storage-driver": "overlay2"
}
EOF
    systemctl enable --now docker
    systemctl restart docker
fi

echo "### CONTAINERD CONFIGURATION (if installed) ###"
if command -v containerd &> /dev/null; then
    mkdir -p /etc/containerd
    containerd config default > /etc/containerd/config.toml
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    systemctl restart containerd
fi

echo "Başarılı, Container Host optimizasyonu tamamlandı!"
echo "Log dosyası: $LOGFILE"
