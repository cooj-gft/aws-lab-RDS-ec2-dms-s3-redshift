locals {
  common_tags = merge(
    {
      Project   = var.name_prefix
      ManagedBy = "Terraform"
    },
    var.tags
  )
}

# --- MÓDULO DE RED (SGs + DB Subnet Group)
module "network" {
  source = "./modules/network"

  name_prefix        = var.name_prefix
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids

  allowed_ssh_sg_ids  = var.allowed_ssh_sg_ids
  allowed_ssh_cidrs   = var.allowed_ssh_cidrs
  tags                = local.common_tags
}

# --- MÓDULO DE EC2 (instancia privada)
module "ec2" {
  source = "./modules/ec2"

  name_prefix               = var.name_prefix
  subnet_id                 = var.private_subnet_ids[0]  # Selecciona una subred privada
  ec2_sg_id                 = module.network.ec2_sg_id

  instance_type             = var.ec2_instance_type
  ami_id                    = var.ec2_ami_id
  ami_ssm_parameter_path    = var.ec2_ami_ssm_parameter_path
  key_name                  = var.ec2_key_name
  enable_ssm                = var.enable_ssm
  tags                      = local.common_tags
}

# --- MÓDULO DE RDS MySQL (privado)
module "rds_mysql" {
  source = "./modules/rds-mysql"

  name_prefix            = var.name_prefix
  db_subnet_group_name   = module.network.rds_db_subnet_group_name
  rds_sg_id              = module.network.rds_sg_id

  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
  instance_class         = var.rds_instance_class
  engine_version         = var.rds_engine_version
  allocated_storage      = var.rds_allocated_storage
  max_allocated_storage  = var.rds_max_allocated_storage
  multi_az               = var.rds_multi_az
  backup_retention_days  = var.rds_backup_retention_period
  deletion_protection    = var.rds_deletion_protection
  kms_key_id             = var.kms_key_id
  apply_immediately      = true
  tags                   = local.common_tags
}
