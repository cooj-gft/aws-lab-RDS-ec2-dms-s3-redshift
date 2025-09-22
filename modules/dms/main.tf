# Rol para S3 target (Parquet y staging Redshift)
data "aws_iam_policy_document" "assume_dms" {
  statement { actions = ["sts:AssumeRole"]; principals { type="Service" identifiers=["dms.amazonaws.com"] } }
}
resource "aws_iam_role" "dms_s3_role" {
  name               = "${var.name_prefix}-dms-s3-role"
  assume_role_policy = data.aws_iam_policy_document.assume_dms.json
  tags               = var.common_tags
}
data "aws_iam_policy_document" "dms_s3_policy" {
  statement {
    effect  = "Allow"
    actions = ["s3:PutObject","s3:DeleteObject","s3:ListBucket","s3:GetBucketLocation","s3:GetObject"]
    resources = [
      "arn:aws:s3:::${var.s3.bucket_name}", "arn:aws:s3:::${var.s3.bucket_name}/*",
      "arn:aws:s3:::${var.redshift.staging_bucket_name}", "arn:aws:s3:::${var.redshift.staging_bucket_name}/*"
    ]
  }
}
resource "aws_iam_policy" "dms_s3_policy" {
  name   = "${var.name_prefix}-dms-s3-policy"
  policy = data.aws_iam_policy_document.dms_s3_policy.json
}
resource "aws_iam_role_policy_attachment" "dms_s3_attach" {
  role       = aws_iam_role.dms_s3_role.name
  policy_arn = aws_iam_policy.dms_s3_policy.arn
}

# Rol DMS VPC
resource "aws_iam_role" "dms_vpc_role" {
  name               = "dms-vpc-role"
  assume_role_policy = data.aws_iam_policy_document.assume_dms.json
  tags               = var.common_tags
}
resource "aws_iam_role_policy_attachment" "dms_vpc_attach" {
  role       = aws_iam_role.dms_vpc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

# Subnet group DMS
resource "aws_dms_replication_subnet_group" "this" {
  replication_subnet_group_id          = "${var.name_prefix}-dms-subnets"
  replication_subnet_group_description = "DMS subnets"
  subnet_ids = var.private_subnet_ids
  depends_on = [aws_iam_role_policy_attachment.dms_vpc_attach]
  tags       = merge(var.common_tags, { Name = "${var.name_prefix}-dms-subnets" })
}

# Endpoint SOURCE (MySQL)
resource "aws_dms_endpoint" "src" {
  endpoint_id   = "${var.name_prefix}-dms-src-mysql"
  endpoint_type = "source"
  engine_name   = var.src.engine_name
  server_name   = var.src.server_name
  port          = var.src.port
  database_name = var.src.database
  username      = var.src.username
  password      = var.src.password
  ssl_mode      = "require"
  tags          = merge(var.common_tags, { Name = "${var.name_prefix}-dms-src-mysql" })
}

# Endpoint TARGET S3 (Parquet)
resource "aws_dms_endpoint" "tgt_s3" {
  endpoint_id   = "${var.name_prefix}-dms-tgt-s3"
  endpoint_type = "target"
  engine_name   = "s3"
  s3_settings {
    service_access_role_arn = aws_iam_role.dms_s3_role.arn
    bucket_name   = var.s3.bucket_name
    bucket_folder = var.s3.bucket_folder
    data_format   = var.s3.parquet ? "parquet" : "csv"
    parquet_version  = var.s3.parquet ? "parquet_2_0" : null
    compression_type = var.s3.compression
  }
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-dms-tgt-s3" })
}

# Endpoint TARGET Redshift Serverless (usa staging S3)
resource "aws_dms_endpoint" "tgt_rs" {
  endpoint_id   = "${var.name_prefix}-dms-tgt-rs"
  endpoint_type = "target"
  engine_name   = "redshift-serverless"
  server_name   = var.redshift.server_name
  port          = var.redshift.port
  database_name = var.redshift.database
  username      = var.redshift.username
  password      = var.redshift.password
  redshift_settings {
    bucket_name   = var.redshift.staging_bucket_name
    bucket_folder = var.redshift.staging_bucket_folder
    encryption_mode = "SSE_S3"
  }
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-dms-tgt-rs" })
}

# Replicación 1: tabla -> S3 Parquet
resource "aws_dms_replication_config" "to_s3" {
  replication_config_identifier = "${var.name_prefix}-rds-to-s3"
  replication_type              = "full-load"
  source_endpoint_arn           = aws_dms_endpoint.src.endpoint_arn
  target_endpoint_arn           = aws_dms_endpoint.tgt_s3.endpoint_arn
  start_replication             = true

  table_mappings = jsonencode({
    rules = [
      { "rule-type":"selection","rule-id":"1","rule-name":"include-to-s3","rule-action":"include",
        "object-locator": { "schema-name": var.schema_name, "table-name": var.table_to_s3 } }
    ]
  })

  compute_config {
    replication_subnet_group_id = aws_dms_replication_subnet_group.this.replication_subnet_group_id
    vpc_security_group_ids      = [var.dms_sg_id]
    min_capacity_units          = 2
    max_capacity_units          = 8
  }
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-dms-repl-to-s3" })
}

# Replicación 2: tabla -> Redshift
resource "aws_dms_replication_config" "to_rs" {
  replication_config_identifier = "${var.name_prefix}-rds-to-redshift"
  replication_type              = "full-load"
  source_endpoint_arn           = aws_dms_endpoint.src.endpoint_arn
  target_endpoint_arn           = aws_dms_endpoint.tgt_rs.endpoint_arn
  start_replication             = true

  table_mappings = jsonencode({
    rules = [
      { "rule-type":"selection","rule-id":"1","rule-name":"include-to-rs","rule-action":"include",
        "object-locator": { "schema-name": var.schema_name, "table-name": var.table_to_redshift } }
    ]
  })

  compute_config {
    replication_subnet_group_id = aws_dms_replication_subnet_group.this.replication_subnet_group_id
    vpc_security_group_ids      = [var.dms_sg_id]
    min_capacity_units          = 2
    max_capacity_units          = 8
  }
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-dms-repl-to-rs" })
}
