
resource "random_password" "vnc_password" {
  length  = 12
  special = true
}

resource "aws_ssm_parameter" "vnc_password" {
  name  = "/packer/vnc-password"
  type  = "SecureString"
  value = random_password.vnc_password.result
}