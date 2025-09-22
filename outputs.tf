output "ec2_private_ip" {
  description = "IP privada de la EC2."
  value       = module.ec2.private_ip
}

output "rds_endpoint" {
  description = "Endpoint privado de RDS MySQL."
  value       = module.rds_mysql.endpoint
}

output "rds_port" {
  description = "Puerto de RDS MySQL."
  value       = module.rds_mysql.port
}


output "vpc_id"               { value = module.network.vpc_id }
output "public_subnet_ids"    { value = module.network.public_subnet_ids }
output "private_subnet_ids"   { value = module.network.private_subnet_ids }

