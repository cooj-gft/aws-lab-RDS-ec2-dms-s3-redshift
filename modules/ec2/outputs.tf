output "instance_id" {
  value       = aws_instance.this.id
  description = "ID de la EC2."
}

output "private_ip" {
  value       = aws_instance.this.private_ip
  description = "IP privada de la EC2."
}

output "ec2_sg_id" {
  value       = aws_security_group.ec2_sg.id
  description = "ID del security group usado por las instancias EC2 (bastion/ec2)."
}
