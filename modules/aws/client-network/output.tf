output "client_vpc" {
  description = "The id of the VPC"
  value       = aws_vpc.client_vpc.id
  depends_on = [aws_route_table_association.client-rt-to-public-subnet]
}

output "raw_vpc" {
  description = "The raw VPC object"
  value       = aws_vpc.client_vpc
  depends_on = [aws_route_table_association.client-rt-to-public-subnet]
}

output "client_subnets" {
  description = "The created subnet"
  value       = aws_subnet.client-public-subnet
}

output "client-security-groups" {
  description = "The ids of security groups"
  value       = [aws_security_group.allow-global.id]
}