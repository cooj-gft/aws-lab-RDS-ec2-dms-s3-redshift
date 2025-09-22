variable "region"          { type = string  default = "us-east-2" }
variable "env"             { type = string  default = "dev" }
variable "stack_id"        { type = string  default = "cdata-bocc-dev" }
variable "repository_url"  { type = string  default = "https://github.com/tu-org/tu-repo" }
variable "sponsor"         { type = string  default = "VP de empresas" }
variable "allowed_ssh_cidr"{ type = string  default = "0.0.0.0/0" }

# RDS MySQL
variable "db_name"          { type = string  default = "appdb" }
variable "db_user"          { type = string  default = "appuser" }
variable "db_password"      { type = string  sensitive = true }
variable "db_instance_class"{ type = string  default = "db.t4g.micro" }

# Esquema/Tablas (en MySQL “schema” = database)
variable "schema_name"       { type = string  default = "appdb" }
variable "table_to_s3"       { type = string  default = "ventas" }
variable "table_to_redshift" { type = string  default = "clientes" }

# EC2
variable "ec2_instance_type" { type = string  default = "t3.micro" }
variable "ec2_key_name"      { type = string  default = null }

# Redshift
variable "redshift_db_name"  { type = string  default = "cdata_redshift_db_dev" }
