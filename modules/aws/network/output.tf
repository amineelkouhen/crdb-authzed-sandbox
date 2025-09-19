output "vpc" {
  description = "The id of the VPC"
  value       = aws_vpc.vpc.id 
  depends_on = [aws_main_route_table_association.rt-main]
}

output "raw_vpc" {
  description = "The raw VPC object"
  value       = aws_vpc.vpc 
  depends_on = [aws_main_route_table_association.rt-main]
}

output "subnets" {
  description = "The created subnets"
  value       = aws_subnet.public-subnets
}

output "security-groups" {
  description = "The ids of security groups"
  value       = [aws_security_group.allow-global.id]
}

output "sql_load_balancer_target_group" {
  description = "The arn of the Load Balancer on port 26257"
  value = aws_lb_target_group.sql_lb_tg.arn
}

output "console_load_balancer_target_group" {
  description = "The arn of the Load Balancer on port 8080"
  value = aws_lb_target_group.console_lb_tg.arn
}

output "nlb_dns_name" {
  description = "DNS name of NLB"
  value       = aws_lb.nlb.dns_name
}