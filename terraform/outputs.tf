output "vpc_id" {
  value = module.vpc.vpc_id
}

output "privatesubnet" {
  value = module.vpc.privatesubnet
}

output "publicsubnet" {
  value = module.vpc.publicsubnet
}

output "availabilityzone" {
  value = module.vpc.availabilityzone
}

output "internetgateway" {
  value = module.vpc.internetgateway
}

output "eip-natgw-publicip" {
  value = module.vpc.eip-natgw-publicip
}

output "natinstance-publicip" {
  value = module.vpc.natinstance-publicip
}

output "gitlab-public-ip" {
  value = aws_instance.i-gitlab.public_ip
}

output "gitlab-password" {
  value = null_resource.ansible-gitlab-getpass.triggers
}