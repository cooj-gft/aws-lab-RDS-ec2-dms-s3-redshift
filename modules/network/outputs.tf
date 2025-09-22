output "vpc_id"              { value = aws_vpc.this.id }
output "public_subnet_id"    { value = aws_subnet.public_a.id }
output "private_subnet_ids"  { value = [aws_subnet.private_a.id, aws_subnet.private_b.id] }
