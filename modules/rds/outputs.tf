output "endpoint" {
  value       = aws_db_instance.mysql.address
  description = "Endpoint de conexión del RDS MySQL."
}

output "port" {
  value       = aws_db_instance.mysql.port
  description = "Puerto MySQL (3306)."
}

output "identifier" {
  value       = aws_db_instance.mysql.id
  description = "Identificador de la instancia RDS."
}
