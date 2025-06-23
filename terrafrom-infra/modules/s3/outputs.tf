output "s3_bucket_name" {
  value = aws_s3_bucket.packer_bucket.id
}

output "s3_arn" {
  value = aws_s3_bucket.packer_bucket.arn
}