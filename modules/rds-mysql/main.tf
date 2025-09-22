resource "aws_security_group" "rds_sg" {
  name   = "${var.name_prefix}-rds-sg"
  vpc_id = var.vpc_id
  egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-rds-sg" })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-rds-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.common_tags, { Name = "${var.name_prefix}-rds-subnets" })
}

resource "aws_db_instance" "this" {
  identifier             = "${var.name_prefix}-rds-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.instance_class
  allocated_storage      = 20
  storage_type           = "gp3"
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  port                   = 3306
  multi_az               = false
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-rds-mysql" })
}

resource "aws_security_group_rule" "ingress_from_external_sgs" {
  for_each = toset(var.ingress_sg_ids)
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = each.value
}