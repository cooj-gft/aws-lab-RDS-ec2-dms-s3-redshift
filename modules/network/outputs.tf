output "vpc_id" {
  value       = aws_vpc.this.id
  description = "ID de la VPC"
}

output "public_subnet_ids" {
  value       = values(aws_subnet.public)[*].id
  description = "IDs de subredes públicas"
}

output "private_subnet_ids" {
  value       = values(aws_subnet.private)[*].id
  description = "IDs de subredes privadas"
}

output "ec2_sg_id" {
  value       = aws_security_group.ec2_sg.id
  description = "SG de EC2"
}

output "rds_sg_id" {
  value       = aws_security_group.rds_sg.id
  description = "SG de RDS"
}

output "rds_db_subnet_group_name" {
  value       = aws_db_subnet_group.rds_subnets.name
  description = "DB Subnet Group (privado) para RDS"
}
