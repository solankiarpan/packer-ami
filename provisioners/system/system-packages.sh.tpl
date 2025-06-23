#!/bin/bash
set -e

echo "[*] System update and desktop install"
sudo dnf -y update
sudo dnf install -y  wget nano tar unzip git make gcc gcc-c++ kernel-devel net-tools iproute rpm-build
sudo dnf groupinstall -y "Server with GUI"
sudo dnf install -y tigervnc-server
