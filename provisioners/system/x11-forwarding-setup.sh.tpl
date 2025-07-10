#!/bin/bash
set -e

echo "[*] Setting up X11 forwarding"

# Install required packages
sudo dnf install -y xorg-x11-xauth mesa-demos xterm

# Configure SSH for X11 forwarding
echo "[*] Configuring SSH"
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Enable X11 forwarding
sudo sed -i 's/#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config
sudo sed -i 's/X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config

# Restart SSH
sudo systemctl restart sshd

echo "[*] X11 forwarding setup complete"
echo "Test with: ssh -X rocky@server-ip"
echo "Then run: glxgears"