# EFS File System
resource "aws_efs_file_system" "packer_efs" {
  creation_token = "rocky-ami-efs"
  encrypted      = true
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"
  tags = {
    Name = "Rocky AMI EFS"
  }
}