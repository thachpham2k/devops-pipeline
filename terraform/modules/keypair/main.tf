# keypair
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "keypair" {
  key_name   = var.key_name
  public_key = tls_private_key.keypair.public_key_openssh
  tags       = var.key_tags
}

resource "local_sensitive_file" "key_file" {
  file_permission = "0400"
  content         = tls_private_key.keypair.private_key_pem
  filename        = var.key_path == "" ? "${path.module}/${var.key_name}-keypair.pem" : "${var.key_path}/${var.key_name}.pem"
}