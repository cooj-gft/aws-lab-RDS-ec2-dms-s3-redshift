output "ec2_sg_id" {
  value       = aws_security_group.ec2_sg.id
  description = "Security Group de la EC2."
}

output "rds_sg_id" {
  value       = aws_security_group.rds_sg.id
  description = "Security Group del RDS."
}

output "rds_db_subnet_group_name" {
  value       = aws_db_subnet_group.rds_subnets.name
  description = "DB Subnet Group para RDS (privado)."
}
