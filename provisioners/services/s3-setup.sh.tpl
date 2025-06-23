#!/bin/bash
set -e

echo "[*] Setting up S3 mounts"

# Check if required variables are set
if [[ -z "${s3_bucket}" ]]; then
    echo "Error: Required variable s3_bucket not set"
    exit 1
fi

# Install AWS CLI and s3fs-fuse
sudo dnf install epel-release -y
sudo dnf install -y s3fs-fuse awscli

# Verify IAM role access
echo "[*] Verifying IAM role access to S3"
aws sts get-caller-identity || {
    echo "Error: Unable to assume IAM role or access AWS services"
    exit 1
}

# Test S3 bucket access
aws s3 ls s3://${s3_bucket}/ --region ${aws_region} || {
    echo "Error: Unable to access S3 bucket ${s3_bucket}"
    exit 1
}

echo "[*] IAM role verification successful"

# Create mount points
sudo mkdir -p /mnt/s3

# Mount S3 bucket using IAM role (no credentials file needed)
echo "Mounting S3 bucket using IAM role..."
sudo s3fs ${s3_bucket} /mnt/s3 -o iam_role=auto,allow_other,endpoint=${aws_region}

# Add to fstab for persistent mounting using IAM role
echo "s3fs#${s3_bucket} /mnt/s3 fuse _netdev,allow_other,iam_role=auto,endpoint=${aws_region} 0 0" | sudo tee -a /etc/fstab

echo "[*] S3 mount setup completed successfully using IAM role"