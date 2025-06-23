# AWS Region
variable "region" {
  description = "The AWS region to build the AMI in"
  type        = string
  default     = "us-west-2"
}

# AMI Name
variable "ami_name" {
  description = "Name of the AMI to be created"
  type        = string
  default     = "rocky-linux-dev-{{timestamp}}"
}

# IAM Instance Profile
variable "instance_profile_name" {
  description = "IAM instance profile name for the EC2 instance"
  type        = string
  # No default - must be provided
}

# EFS File System ID
variable "efs_id" {
  description = "EFS file system ID to mount"
  type        = string
  # No default - must be provided
}

# S3 Bucket
variable "s3_bucket" {
  description = "S3 bucket name to mount"
  type        = string
  # No default - must be provided
}

# VNC Password SSM Parameter
variable "vnc_password_parameter" {
  description = "SSM Parameter Store path for VNC password (e.g., /rocky-ami/vnc-password)"
  type        = string
  # No default - must be provided
}

# Optional: VPC Configuration
variable "vpc_id" {
  description = "VPC ID to launch the instance in"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance in"
  type        = string
  default     = null
}

variable "security_group_id" {
  description = "Security Group ID for the instance"
  type        = string
  default     = null
}