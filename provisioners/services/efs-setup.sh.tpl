#!/bin/bash
set -e 
echo "[*] Mounting EFS"

# Clone and build EFS utils
git clone https://github.com/aws/efs-utils.git
cd efs-utils
git checkout v1.35.0
make rpm
sudo dnf install -y build/amazon-efs-utils-*.rpm

# Return to original directory
cd ..

# Create EFS mount point
sudo mkdir -p /mnt/efs

# Mount EFS filesystem
echo "Mounting EFS filesystem ${efs_id}..."
sudo mount -t efs ${efs_id}:/ /mnt/efs

# Add to fstab for persistent mounting
echo "${efs_id}.efs.us-west-2.amazonaws.com:/ /mnt/efs efs defaults,_netdev 0 0" | sudo tee -a /etc/fstab

# Set proper permissions for write access
sudo chown rocky:rocky /mnt/efs
sudo chmod 755 /mnt/efs

echo "[*] EFS utils installation and mounting completed"