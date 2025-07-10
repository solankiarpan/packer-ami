# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group that allows NFS only within the VPC
resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Allow NFS access within VPC"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EFS file system
resource "aws_efs_file_system" "packer_efs" {
  creation_token   = "rocky-ami-efs"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"

  tags = {
    Name = "Rocky AMI EFS"
  }
}

# Mount target in each subnet
resource "aws_efs_mount_target" "packer_efs_target" {
  for_each = toset(data.aws_subnets.default.ids)

  file_system_id  = aws_efs_file_system.packer_efs.id
  subnet_id       = each.key
  security_groups = [aws_security_group.efs_sg.id]
}