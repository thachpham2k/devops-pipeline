output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "privatesubnet" {
  value = zipmap(tolist(aws_subnet.privatesubnet)[*].id, tolist(aws_subnet.privatesubnet)[*].cidr_block)
}

output "publicsubnet" {
  value = zipmap(tolist(aws_subnet.publicsubnet)[*].id, tolist(aws_subnet.publicsubnet)[*].cidr_block)
}

output "availabilityzone" {
  value = data.aws_availability_zones.availability_zone.names
}

output "internetgateway" {
  value = aws_internet_gateway.internet_gateway.id
}

output "eip-natgw-publicip" {
  value = length(aws_eip.eip) > 0 ? aws_eip.eip[0].public_ip : null
}

output "natinstance-publicip" {
  value = length(aws_instance.natinstance) > 0 ? aws_instance.natinstance[0].public_ip : null
}