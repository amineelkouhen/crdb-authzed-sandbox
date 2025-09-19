output "cr-nodes" {
  description = "The CRDB Cluster nodes"
  value = aws_instance.node
  sensitive = true
}

output "cr-public-ips" {
  description = "Public IP addresses of all CRDB cluster nodes"
  value       = aws_instance.node[*].public_ip
}

output "cr-private-ips" {
  description = "Private IP addresses of all CRDB cluster nodes"
  value       = aws_network_interface.cluster_nic[*].private_ip
}