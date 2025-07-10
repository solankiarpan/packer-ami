# S3 Module
module "s3" {
  source = "./modules/s3"
  s3_bucket_name = "packer-rocky-ami-bucket-cloudburfi"
}

# EFS Module
module "efs" {
  source = "./modules/efs"
}

# VNC SSM Module
module "vnc_ssm" {
  source = "./modules/vnc-ssm"

}

# IAM Role Module
module "iam_role" {
  source = "./modules/iam-role"
  s3_bucket_arn = module.s3.s3_arn
  vnc_password_ssm_arn = module.vnc_ssm.vnc_ssm_arn
}