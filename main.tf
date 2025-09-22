terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 6.13" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      stack_id   = var.stack_id
      repository = var.repository_url
      sponsor    = var.sponsor
      cod_app    = "519"
    }
  }
}

locals {
  name_prefix = var.stack_id
  common_tags = {
    stack_id   = var.stack_id
    repository = var.repository_url
    sponsor    = var.sponsor
    cod_app    = "519"
  }
}

module "network" {
  source = "./modules/network"
  name_prefix = local.name_prefix
  region      = var.region
  common_tags = local.common_tags
}

# Buckets (datalake Parquet + staging Redshift)
module "bucket_names" {
  source  = "hashicorp/random/null" # solo para namespacing de ejemplo
}

resource "aws_s3_bucket" "data_parquet" {
  bucket = "${local.name_prefix}-datalake-parquet"
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-datalake-parquet" })
}
resource "aws_s3_bucket_server_side_encryption_configuration" "data_parquet" {
  bucket = aws_s3_bucket.data_parquet.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}
resource "aws_s3_bucket_public_access_block" "data_parquet" {
  bucket = aws_s3_bucket.data_parquet.id
  block_public_acls = true; block_public_policy = true; restrict_public_buckets = true; ignore_public_acls = true
}

resource "aws_s3_bucket" "rs_staging" {
  bucket = "${local.name_prefix}-redshift-staging"
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-redshift-staging" })
}
resource "aws_s3_bucket_server_side_encryption_configuration" "rs_staging" {
  bucket = aws_s3_bucket.rs_staging.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}
resource "aws_s3_bucket_public_access_block" "rs_staging" {
  bucket = aws_s3_bucket.rs_staging.id
  block_public_acls = true; block_public_policy = true; restrict_public_buckets = true; ignore_public_acls = true
}

# RDS MySQL modular
module "rds_mysql" {
  source = "./modules/rds-mysql"
  name_prefix          = local.name_prefix
  vpc_id               = module.network.vpc_id
  private_subnet_ids   = module.network.private_subnet_ids
  db_name              = var.db_name
  db_username          = var.db_user
  db_password          = var.db_password
  instance_class       = var.db_instance_class
  ingress_sg_ids       = [] # luego agregamos DMS/EC2
  common_tags          = local.common_tags
}

# SG DMS (para permitir salida y acceso a RDS/Redshift)
resource "aws_security_group" "dms_sg" {
  name   = "${local.name_prefix}-dms-sg"
  vpc_id = module.network.vpc_id
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-dms-sg" })
}

# SG EC2 (SSH)
resource "aws_security_group" "ec2_sg" {
  name   = "${local.name_prefix}-ec2-sg"
  vpc_id = module.network.vpc_id
  ingress { description="SSH" from_port=22 to_port=22 protocol="tcp" cidr_blocks=[var.allowed_ssh_cidr] }
  egress  { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-ec2-sg" })
}

# Autoriza EC2 y DMS hacia MySQL (3306)
resource "aws_security_group_rule" "rds_from_ec2" {
  type                     = "ingress"
  description              = "MySQL from EC2"
  from_port = 3306; to_port = 3306; protocol = "tcp"
  security_group_id        = module.rds_mysql.rds_sg_id
  source_security_group_id = aws_security_group.ec2_sg.id
}
resource "aws_security_group_rule" "rds_from_dms" {
  type                     = "ingress"
  description              = "MySQL from DMS"
  from_port = 3306; to_port = 3306; protocol = "tcp"
  security_group_id        = module.rds_mysql.rds_sg_id
  source_security_group_id = aws_security_group.dms_sg.id
}

# Redshift Serverless (namespace + workgroup)
resource "aws_security_group" "rs_sg" {
  name   = "${local.name_prefix}-redshift-sg"
  vpc_id = module.network.vpc_id
  ingress {
    description = "Redshift 5439 from DMS"
    from_port = 5439; to_port = 5439; protocol = "tcp"
    source_security_group_id = aws_security_group.dms_sg.id
  }
  egress  { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-redshift-sg" })
}

resource "aws_redshiftserverless_namespace" "ns" {
  namespace_name = "${local.name_prefix}-ns"
  db_name        = var.redshift_db_name
  tags           = merge(local.common_tags, { Name = "${local.name_prefix}-rs-ns" })
}

resource "aws_redshiftserverless_workgroup" "wg" {
  workgroup_name       = "${local.name_prefix}-wg"
  namespace_name       = aws_redshiftserverless_namespace.ns.namespace_name
  base_capacity        = 8
  publicly_accessible  = false
  security_group_ids   = [aws_security_group.rs_sg.id]
  subnet_ids           = module.network.private_subnet_ids
  enhanced_vpc_routing = true
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-rs-wg" })
}

# DMS Serverless modular (dos pipelines: MySQL->S3 Parquet y MySQL->Redshift)
module "dms_serverless" {
  source = "./modules/dms"

  name_prefix = local.name_prefix
  vpc_id      = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  dms_sg_id   = aws_security_group.dms_sg.id

  # Source: RDS MySQL
  src = {
    engine_name  = "mysql"
    server_name  = module.rds_mysql.endpoint_address
    port         = 3306
    database     = var.db_name
    username     = var.db_user
    password     = var.db_password
  }

  # Target S3 (Parquet)
  s3 = {
    bucket_name   = aws_s3_bucket.data_parquet.bucket
    bucket_folder = "from-dms/${var.schema_name}/${var.table_to_s3}"
    parquet       = true
    compression   = "GZIP"
  }

  # Target Redshift Serverless (usa staging S3)
  redshift = {
    server_name   = aws_redshiftserverless_workgroup.wg.endpoint[0].address
    port          = 5439
    database      = var.redshift_db_name
    username      = aws_redshiftserverless_namespace.ns.admin_username
    password      = aws_redshiftserverless_namespace.ns.admin_user_password
    staging_bucket_name   = aws_s3_bucket.rs_staging.bucket
    staging_bucket_folder = "dms-staging/${var.schema_name}/${var.table_to_redshift}"
  }

  # Selección de tablas
  schema_name       = var.schema_name
  table_to_s3       = var.table_to_s3       # ventas -> S3 Parquet
  table_to_redshift = var.table_to_redshift # clientes -> Redshift

  common_tags = local.common_tags
}

# EC2 “jump box” para ver tablas/datos (cliente MySQL)
module "ec2_ami" { source = "hashicorp/random/null" } # placeholder

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"]
  filter { name = "name" values = ["al2023-ami-*-x86_64"] }
}


module "ec2" {
    source = "./modules/ec2"
  subnet_id = module.networking.public_subnet_id
  security_group_id = module.networking.db_sg_id

}