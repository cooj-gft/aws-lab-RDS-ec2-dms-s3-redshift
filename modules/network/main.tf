resource "aws_security_group" "ec2_sg" {
  name        = "${var.name_prefix}-ec2-sg"
  description = "Acceso controlado a EC2 (SSH privado)"
  vpc_id      = var.vpc_id

  # Salida abierta para actualizaciones y SSM
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}

resource "aws_security_group_rule" "ec2_ssh_from_sg" {
  for_each                 = toset(var.allowed_ssh_sg_ids)
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2_sg.id
  source_security_group_id = each.value
  description              = "SSH privado desde SG ${each.value}"
}

resource "aws_security_group_rule" "ec2_ssh_from_cidr" {
  for_each          = toset(var.allowed_ssh_cidrs)
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2_sg.id
  cidr_blocks       = [each.value]
  description       = "SSH privado desde ${each.value}"
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Permite MySQL 3306 solo desde la SG de la EC2"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "rds_mysql_from_ec2" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.ec2_sg.id
  description              = "MySQL privado desde EC2"
}

resource "aws_db_subnet_group" "rds_subnets" {
  name       = "${var.name_prefix}-rds-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}
