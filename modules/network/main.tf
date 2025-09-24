data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

locals {
  azs               = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  # Plan: 1 subnet pública + 1 privada por AZ. Usamos índices disjuntos.
  public_netnums    = { for idx, az in local.azs : az => idx }
  private_netnums   = { for idx, az in local.azs : az => idx + var.az_count }
}

# ------------------------------
# VPC + IGW
# ------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}

# ------------------------------
# Subredes públicas
# ------------------------------
resource "aws_subnet" "public" {
  for_each = local.public_netnums
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.public_subnet_newbits, each.value)
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${each.key}"
    Tier = "public"
  })
}

# Tabla de ruteo pública (+ asociación a IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-rt-public" })
}

resource "aws_route" "public_0_0_0_0" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------
# Subredes privadas
# ------------------------------
resource "aws_subnet" "private" {
  for_each = local.private_netnums
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.private_subnet_newbits, each.value)
  availability_zone = each.key
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${each.key}"
    Tier = "private"
  })
}

# NAT: single o por AZ (opcional)
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(local.azs)) : 0
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name_prefix}-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(local.azs)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(values(aws_subnet.public)[*].id, var.single_nat_gateway ? 0 : count.index)
  tags          = merge(var.tags, { Name = "${var.name_prefix}-nat-${count.index}" })
  depends_on    = [aws_internet_gateway.igw]
}

# Tabla(s) privada(s) + rutas por NAT (si aplica)
resource "aws_route_table" "private" {
  count = var.enable_nat_gateway && !var.single_nat_gateway ? length(local.azs) : 1
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-rt-private-${count.index}" })
}

resource "aws_route" "private_to_nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(local.azs)) : 0
  route_table_id         = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}

# Asociar cada subred privada a su RT (si single NAT, todos a la misma)
resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private
  subnet_id = each.value.id
  route_table_id = aws_route_table.private[
    var.enable_nat_gateway && !var.single_nat_gateway ?
    index(local.azs, each.value.availability_zone) : 0
  ].id
}

# ------------------------------
# SGs (sin mezclar reglas inline con recursos de reglas)
# ------------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "${var.name_prefix}-ec2-sg"
  description = "Acceso controlado a EC2 (SSH privado)."
  vpc_id      = aws_vpc.this.id
  tags        = var.tags
}

# SSH desde SGs
resource "aws_security_group_rule" "ec2_ssh_from_sg" {
  for_each                 = toset(var.allowed_ssh_sg_ids)
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2_sg.id
  source_security_group_id = each.value
  description              = "SSH privado desde SG ${each.value}"
}

# SSH desde CIDRs específicas
resource "aws_security_group_rule" "ec2_ssh_from_cidr" {
  for_each          = toset(var.allowed_ssh_cidrs)
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2_sg.id
  cidr_blocks       = [each.value]
  description       = "SSH privado desde ${each.value}"
}

resource "aws_security_group_rule" "ec2_egress_all_ec2" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.ec2_sg.id
  description       = "Permitir todo el tráfico de salida"
}

# Egress por defecto: AWS crea "allow all". No añadimos inline rules.

resource "aws_security_group" "rds_sg" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Permite MySQL 3306 solo desde SG de EC2"
  vpc_id      = aws_vpc.this.id
  tags        = var.tags
}

resource "aws_security_group_rule" "rds_mysql_from_ec2" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.ec2_sg.id
  description              = "MySQL desde EC2"
}

resource "aws_security_group_rule" "ec2_egress_all_rds" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.rds_sg.id
  description       = "Permitir todo el tráfico de salida"
}

# ------------------------------
# DB Subnet Group (privado)
# ------------------------------
resource "aws_db_subnet_group" "rds_subnets" {
  name       = "${var.name_prefix}-rds-subnets"
  subnet_ids = values(aws_subnet.private)[*].id
  tags       = var.tags
}

# ------------------------------
# (Opcional) VPC Endpoints para SSM (para no usar NAT)
# ------------------------------
resource "aws_security_group" "vpce_ssm_sg" {
  count       = var.enable_ssm_endpoints ? 1 : 0
  name        = "${var.name_prefix}-vpce-ssm-sg"
  description = "Permite 443 desde EC2 SG hacia endpoints SSM"
  vpc_id      = aws_vpc.this.id
  tags        = var.tags
}

# Permite 443 desde la SG de EC2 a los ENIs de los endpoints
resource "aws_security_group_rule" "vpce_in_443_from_ec2" {
  count                   = var.enable_ssm_endpoints ? 1 : 0
  type                    = "ingress"
  from_port               = 443
  to_port                 = 443
  protocol                = "tcp"
  security_group_id       = aws_security_group.vpce_ssm_sg[0].id
  source_security_group_id= aws_security_group.ec2_sg.id
  description             = "TLS desde EC2 a endpoints SSM"
}

# Endpoints (Interface) en subredes privadas
resource "aws_vpc_endpoint" "ssm" {
  count              = var.enable_ssm_endpoints ? 1 : 0
  vpc_id             = aws_vpc.this.id
  service_name       = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = values(aws_subnet.private)[*].id
  security_group_ids = [aws_security_group.vpce_ssm_sg[0].id]
  private_dns_enabled = true
  tags               = var.tags
}

resource "aws_vpc_endpoint" "ec2messages" {
  count              = var.enable_ssm_endpoints ? 1 : 0
  vpc_id             = aws_vpc.this.id
  service_name       = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = values(aws_subnet.private)[*].id
  security_group_ids = [aws_security_group.vpce_ssm_sg[0].id]
  private_dns_enabled = true
  tags               = var.tags
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count              = var.enable_ssm_endpoints ? 1 : 0
  vpc_id             = aws_vpc.this.id
  service_name       = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = values(aws_subnet.private)[*].id
  security_group_ids = [aws_security_group.vpce_ssm_sg[0].id]
  private_dns_enabled = true
  tags               = var.tags
}
