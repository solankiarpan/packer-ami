# AWS Region
region = "us-west-2"

# AMI Name (timestamp will be automatically added)
ami_name = "rocky-linux-dev-{{timestamp}}"

# IAM Instance Profile (created by Terraform)
instance_profile_name = "packer-rocky-ami-profile"

# EFS File System ID (from Terraform output)
efs_id = "fs-06a2c6cbd359b4095"

# S3 Bucket Name (from Terraform output)
s3_bucket = "cloudburfi-packer-rocky-ami-bucket"

# SSM Parameter for VNC Password
vnc_password_parameter = "/packer/vnc-password"

# Optional: VPC Configuration (uncomment if needed)
# vpc_id = "vpc-0123456789abcdef0"
# subnet_id = "subnet-0123456789abcdef0"
# security_group_id = "sg-0123456789abcdef0"