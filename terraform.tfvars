aws_region  = "us-east-1"
stack_id    = "mi-stack-id"
repository_url = "https://github.com/cooj-gft/aws-lab-RDS-ec2-dms-s3-redshift"
sponsor     = "mi-sponsor"
name_prefix = "mi-org-app-dev"

# --- VPC
vpc_cidr   = "10.0.0.0/16"
az_count   = 2

# --- NAT/SSM
enable_nat_gateway   = true     # o false si usas endpoints de SSM
single_nat_gateway   = true
enable_ssm_endpoints = false    # ponlo en true si desactivas NAT

# --- SSH privado (idealmente usa SSM y deja esto vacío)
allowed_ssh_sg_ids = []
allowed_ssh_cidrs  = []

# --- EC2
ec2_instance_type          = "t3.micro"
ec2_ami_id                 = null
ec2_ami_ssm_parameter_path = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
enable_ssm                 = true

# --- RDS
db_name                    = "appdb"
db_username                = "admin"
db_password                = "CambiarME123456!"
rds_instance_class         = "db.t3.micro"
rds_engine_version         = "8.0.34"
rds_allocated_storage      = 20
rds_max_allocated_storage  = 100
rds_multi_az               = true
rds_backup_retention_days  = 7
rds_deletion_protection    = true

tags = {
  owner       = "data-team"
  environment = "dev"
  cost_center = "CC-001"
}
