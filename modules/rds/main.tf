resource "aws_db_instance" "mysql" {
  identifier                 = "${var.name_prefix}-mysql"
  engine                     = "mysql"
  engine_version             = var.engine_version
  instance_class             = var.instance_class

  db_name                    = var.db_name
  username                   = var.db_username
  password                   = var.db_password

  allocated_storage          = var.allocated_storage
  max_allocated_storage      = var.max_allocated_storage

  db_subnet_group_name       = var.db_subnet_group_name
  vpc_security_group_ids     = [var.rds_sg_id]
  publicly_accessible        = false
  multi_az                   = var.multi_az
  backup_retention_period    = var.backup_retention_days
  deletion_protection        = var.deletion_protection
  apply_immediately          = var.apply_immediately

  storage_encrypted          = true
  kms_key_id                 = var.kms_key_id

  auto_minor_version_upgrade = true
  skip_final_snapshot        = true

  tags = var.tags
}
