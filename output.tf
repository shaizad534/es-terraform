# Outputs.tf

output "elastic-search_instance_id" {
  description = " Instance ID of the instance"
  value       = aws_instance.elastic-search.id
}

output "elastic-search_instance_IP" {
  description = " Public IP of the instances"
  value       = aws_instance.elastic-search.public_ip
}

output "private_key" {
  description = "Key of the ec2 instance "
  value       = tls_private_key.my_key.private_key_pem
  sensitive   = true 
}

output "vpc_id" {
  value = aws_vpc.vpc_name.id
}

output "vpc_public_sn_id" {
  value = aws_subnet.vpc_public_sn.id
}

output "vpc_private_sn_id" {
  value = aws_subnet.vpc_private_sn.id
}
