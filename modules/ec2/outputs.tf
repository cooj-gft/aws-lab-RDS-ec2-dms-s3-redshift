output "instance_id" {
  value       = aws_instance.this.id
  description = "ID de la EC2."
}

output "private_ip" {
  value       = aws_instance.this.private_ip
  description = "IP privada de la EC2."
}
