variable "name_prefix"        { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "dms_sg_id"          { type = string }
variable "common_tags"        { type = map(string) }

# Source MySQL (RDS)
variable "src" {
  type = object({
    engine_name = string # "mysql"
    server_name = string
    port        = number # 3306
    database    = string
    username    = string
    password    = string
  })
}

# S3 Parquet target
variable "s3" {
  type = object({
    bucket_name   = string
    bucket_folder = string
    parquet       = bool
    compression   = string
  })
}

# Redshift Serverless target + S3 staging
variable "redshift" {
  type = object({
    server_name   = string
    port          = number
    database      = string
    username      = string
    password      = string
    staging_bucket_name   = string
    staging_bucket_folder = string
  })
}

# Tablas
variable "schema_name"       { type = string }
variable "table_to_s3"       { type = string }
variable "table_to_redshift" { type = string }
