resource "aws_s3_bucket" "data_parquet" {
  bucket = "${local.name_prefix}-datalake-parquet"
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-datalake-parquet" })
}

resource "aws_s3_bucket_versioning" "data_parquet" {
  bucket = aws_s3_bucket.data_parquet.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_parquet" {
  bucket = aws_s3_bucket.data_parquet.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}

resource "aws_s3_bucket_public_access_block" "data_parquet" {
  bucket                  = aws_s3_bucket.data_parquet.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

# Staging para Redshift (DMS -> S3 -> Redshift)
resource "aws_s3_bucket" "rs_staging" {
  bucket = "${local.name_prefix}-redshift-staging"
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-redshift-staging" })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "rs_staging" {
  bucket = aws_s3_bucket.rs_staging.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}

resource "aws_s3_bucket_public_access_block" "rs_staging" {
  bucket                  = aws_s3_bucket.rs_staging.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}
