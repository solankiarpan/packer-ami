#!/bin/bash
set -e
echo "[*] Installing VS Code"
# Add Microsoft's GPG key and repository
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
# Install VS Code (skip check-update as it can return exit code 100)
sudo dnf install -y code

# echo "[*] Git Artifactory setup"
# git config --system url."https://my-artifactory.example.com/artifactory/".insteadOf "https://github.com/"

echo "[*] Sublime Text install"
# FIX: Add sudo for rpm command
sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
sudo dnf install -y sublime-text