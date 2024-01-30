output "keypair-name" {
  value = aws_key_pair.keypair.key_name
}

output "keypairpublic" {
  value = tls_private_key.keypair.public_key_pem
}

output "keypaiprivate" {
  value     = tls_private_key.keypair.private_key_pem
  sensitive = true
}