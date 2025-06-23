#!/bin/bash
set -e

echo "[*] Temporarily disabling SELinux to avoid passt installation issues"
# Temporarily set SELinux to permissive mode
sudo setenforce 0 || true
# Backup and modify SELinux config
sudo cp /etc/selinux/config /etc/selinux/config.backup
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
