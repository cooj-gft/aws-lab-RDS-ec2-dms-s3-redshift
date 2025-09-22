# --- RED (crea VPC, subredes, IGW, NAT opcional, rutas, SGs, DB Subnet Group, endpoints SSM opcional)
module "network" {
  source = "./modules/network"

  name_prefix             = var.name_prefix
  vpc_cidr                = var.vpc_cidr
  az_count                = var.az_count
  public_subnet_newbits   = var.public_subnet_newbits
  private_subnet_newbits  = var.private_subnet_newbits
  enable_nat_gateway      = var.enable_nat_gateway
  single_nat_gateway      = var.single_nat_gateway
  enable_ssm_endpoints    = var.enable_ssm_endpoints

  allowed_ssh_sg_ids      = var.allowed_ssh_sg_ids
  allowed_ssh_cidrs       = var.allowed_ssh_cidrs

  tags                    = local.common_tags
}

# --- EC2 PRIVADA
module "ec2" {
  source = "./modules/ec2"

  name_prefix            = var.name_prefix
  subnet_id              = module.network.private_subnet_ids[0]
  ec2_sg_id              = module.network.ec2_sg_id

  instance_type          = var.ec2_instance_type
  ami_id                 = var.ec2_ami_id
  ami_ssm_parameter_path = var.ec2_ami_ssm_parameter_path
  key_name               = var.ec2_key_name
  enable_ssm             = var.enable_ssm

  tags                   = local.common_tags
}

# --- RDS MySQL PRIVADO
module "rds_mysql" {
  source = "./modules/rds-mysql"

  name_prefix           = var.name_prefix
  db_subnet_group_name  = module.network.rds_db_subnet_group_name
  rds_sg_id             = module.network.rds_sg_id

  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  instance_class        = var.rds_instance_class
  engine_version        = var.rds_engine_version
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  multi_az              = var.rds_multi_az
  backup_retention_days = var.rds_backup_retention_days
  deletion_protection   = var.rds_deletion_protection
  kms_key_id            = var.kms_key_id
  apply_immediately     = true

  tags                  = local.common_tags
}
