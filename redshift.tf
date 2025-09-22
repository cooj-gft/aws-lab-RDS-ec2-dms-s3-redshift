# SG para Redshift Serverless
resource "aws_security_group" "rs_sg" {
  name   = "${local.name_prefix}-redshift-sg"
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-redshift-sg" })

  ingress {
    description     = "Redshift 5439 from DMS"
    from_port       = 5439
    to_port         = 5439
    protocol        = "tcp"
    security_groups = [aws_security_group.dms_sg.id]
  }

  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_redshiftserverless_namespace" "ns" {
  namespace_name = "${local.name_prefix}-ns"
  db_name        = var.redshift_db_name
  tags           = merge(local.common_tags, { Name = "${local.name_prefix}-rs-ns" })
}

resource "aws_redshiftserverless_workgroup" "wg" {
  workgroup_name        = "${local.name_prefix}-wg"
  namespace_name        = aws_redshiftserverless_namespace.ns.namespace_name
  base_capacity         = 8
  publicly_accessible   = false
  security_group_ids    = [aws_security_group.rs_sg.id]
  subnet_ids            = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  enhanced_vpc_routing  = true
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-rs-wg" })
}
