output "public_ip" {
  value = aws_instance.ec2_lab1_camilo.public_ip
}
output "instance_id" {
  value = aws_instance.ec2_lab1_camilo.id
}