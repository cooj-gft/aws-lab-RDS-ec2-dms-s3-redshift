resource "aws_vpc" "this" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "${var.name_prefix}-igw" })
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-subnet-public-a" })
}
resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.this.id
  cidr_block        = "10.20.10.0/24"
  availability_zone = "${var.region}a"
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-subnet-private-a" })
}
resource "aws_subnet" "private_b" {
  vpc_id = aws_vpc.this.id
  cidr_block        = "10.20.11.0/24"
  availability_zone = "${var.region}b"
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-subnet-private-b" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route { cidr_block = "0.0.0.0/0"; gateway_id = aws_internet_gateway.igw.id }
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-rt-public" })
}
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# VPC endpoint S3 (gateway) — evita NAT para S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id           = aws_vpc.this.id
  service_name     = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids  = [aws_route_table.public.id]
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-vpce-s3" })
}
