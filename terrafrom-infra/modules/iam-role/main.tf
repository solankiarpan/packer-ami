# IAM Role for EC2 Instance
resource "aws_iam_role" "packer_role" {
  name = "packer-rocky-ami-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "Packer Rocky AMI Role"
  }
}

# IAM Policy for the role
resource "aws_iam_role_policy" "packer_policy" {
  name = "packer-rocky-ami-policy"
  role = aws_iam_role.packer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${var.s3_bucket_arn}/*",
          "${var.s3_bucket_arn}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "${var.vnc_password_ssm_arn}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "packer_profile" {
  name = "packer-rocky-ami-profile"
  role = aws_iam_role.packer_role.name

  tags = {
    Name        = "Packer Rocky AMI Instance Profile"
  }
}