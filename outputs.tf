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

output "rds_security_group_id" {
  description = "ID de la SG del RDS."
  value       = module.network.rds_sg_id
}
