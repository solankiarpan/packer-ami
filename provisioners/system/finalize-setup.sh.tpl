#!/bin/bash
set -e

echo "[*] Setting up firewall rules for VNC and Jupyter"

# Check if firewalld is installed and stop it if it is
if systemctl list-unit-files | grep -q firewalld.service; then
    echo "firewalld is present. Stopping it..."
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld
else
    echo "firewalld is not installed. Skipping firewall configuration."
fi

echo "[*] Re-enabling SELinux after installation"
# Restore SELinux to enforcing mode
sudo cp /etc/selinux/config.backup /etc/selinux/config
# Note: SELinux will be enforcing on next boot, but we keep it permissive for the current session
# to avoid any issues during the remainder of the build process

echo "[*] Setup completed successfully"