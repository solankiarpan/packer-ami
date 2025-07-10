# AWS Region
region = "us-west-2"

# AMI Name (timestamp will be automatically added)
ami_name = "rocky-linux-dev-{{timestamp}}"

# IAM Instance Profile (created by Terraform)
instance_profile_name = "packer-rocky-ami-profile"

# EFS File System ID (from Terraform output)
efs_id = "fs-0328ffdf76ef2d4f1"

# S3 Bucket Name (from Terraform output)
s3_bucket = "packer-rocky-ami-bucket-cloudburfi"

# SSM Parameter for VNC Password
vnc_password_parameter = "/packer/vnc-password"

# Okta ASA Configuration (optional)
okta_canonical_name = "rocky-dev-server"
okta_team_name     = "okta-team"

# Optional: VPC Configuration (uncomment if needed)
# vpc_id = "vpc-0123456789abcdef0"
# subnet_id = "subnet-0123456789abcdef0"
# security_group_id = "sg-0123456789abcdef0"