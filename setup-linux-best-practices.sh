#!/bin/bash
# CentOS 9 - Linux Best Practices Script
# Author: Savaş Enes Erateşli
# Purpose: Güvenlik, performans ve temel sistem optimizasyonu
# --------------------------------------

LOGFILE="/var/log/linux-best-practices.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "### SYSTEM UPDATE ###"
dnf update -y && dnf upgrade -y

echo "### ENABLE AUTOMATIC SECURITY UPDATES ###"
dnf install -y dnf-automatic
systemctl enable --now dnf-automatic.timer

echo "### FIREWALL SETUP ###"
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

echo "### SSH HARDENING ###"
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

echo "### FAIL2BAN INSTALL ###"
dnf install -y fail2ban
systemctl enable --now fail2ban

echo "### AUDITD ENABLE ###"
dnf install -y audit
systemctl enable --now auditd

echo "### SELINUX ENFORCING ###"
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
setenforce 1

echo "### PERFORMANCE TOOLS ###"
dnf install -y htop iotop iftop nmon sysstat net-tools
systemctl enable --now sysstat

echo "### SYSCTL OPTIMIZATION ###"
cat <<EOF >/etc/sysctl.d/99-system.conf
vm.swappiness = 10
fs.file-max = 2097152
EOF
sysctl --system

echo "### TIMEZONE & NTP ###"
timedatectl set-timezone Europe/Istanbul
dnf install -y chrony
systemctl enable --now chronyd

echo "### AIDE INTEGRITY CHECKER ###"
dnf install -y aide
aide --init
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

echo "### CLEANUP ###"
dnf autoremove -y

echo "Başarılı, Linux Best Practice yapılandırması tamamlandı!"
echo "Log dosyası: $LOGFILE"
