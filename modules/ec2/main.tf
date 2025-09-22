# Resolver AMI si no viene especificada
data "aws_ssm_parameter" "ami_param" {
  name = var.ami_ssm_parameter_path
}

locals {
  final_ami = var.ami_id != null ? var.ami_id : data.aws_ssm_parameter.ami_param.value
}

# IAM para SSM (opcional)
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ssm_role" {
  count              = var.enable_ssm ? 1 : 0
  name               = "${var.name_prefix}-ec2-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  count = var.enable_ssm ? 1 : 0
  name  = "${var.name_prefix}-ec2-ssm-profile"
  role  = aws_iam_role.ssm_role[0].name
}

resource "aws_instance" "this" {
  ami                         = local.final_ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.ec2_sg_id]
  associate_public_ip_address = false
  key_name                    = var.key_name

  iam_instance_profile = var.enable_ssm ? aws_iam_instance_profile.ssm_profile[0].name : null

  metadata_options {
    http_tokens = "required"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-ec2" })
}
