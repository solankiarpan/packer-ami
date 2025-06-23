# S3 Bucket for mounting
resource "aws_s3_bucket" "packer_bucket" {
  bucket = var.s3_bucket_name # You'll need to define this variable

  tags = {
    Name        = "Rocky AMI S3 Mount"
  }
}