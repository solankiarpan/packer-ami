variable "s3_bucket_arn" {
  description = "ARN for the S3 bucket"
  type        = string
}
variable "vnc_password_ssm_arn" {
  description = "ARN for the VNC password SSM"
  type        = string
}