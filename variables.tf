variable "aws_region" {
  type        = string
  description = "Región AWS (ej: us-east-1)."
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d+$", var.aws_region))
    error_message = "Debe ser una región válida (ej: us-east-1)."
  }
}

variable "name_prefix" {
  type        = string
  description = "Prefijo estándar para nombres (ej: org-app-env)."
}

variable "tags" {
  type        = map(string)
  description = "Etiquetas comunes (owner, cost_center, environment, etc.)."
  default     = {}
}

# Red
variable "vpc_id" {
  type        = string
  description = "ID de la VPC existente."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "IDs de subredes privadas (>=2 recomendado para HA)."
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "Provee al menos 2 subredes privadas."
  }
}

# SSH controlado
variable "allowed_ssh_sg_ids" {
  type        = list(string)
  default     = []
  description = "SGs desde donde se permite SSH (22) a la EC2 (p.ej. bastión)."
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDRs permitidos para SSH a la EC2 (no usar 0.0.0.0/0)."
  validation {
    condition     = alltrue([for c in var.allowed_ssh_cidrs : !(c == "0.0.0.0/0" || c == "::/0")])
    error_message = "Por seguridad no se permite 0.0.0.0/0 o ::/0."
  }
}

# EC2
variable "ec2_instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Tipo de instancia EC2."
}

variable "ec2_ami_id" {
  type        = string
  default     = null
  description = "AMI ID explícito. Si es null, se usará SSM para Amazon Linux 2023."
}

variable "ec2_ami_ssm_parameter_path" {
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  description = "Parámetro SSM para resolver automáticamente la última AMI AL2023."
}

variable "ec2_key_name" {
  type        = string
  default     = null
  description = "Par de llaves para SSH (si usas SSH tradicional además de SSM)."
}

variable "enable_ssm" {
  type        = bool
  default     = true
  description = "Adjunta rol IAM para usar AWS Systems Manager Session Manager."
}

# RDS MySQL
variable "db_name" {
  type        = string
  description = "Nombre de la base inicial en MySQL."
}

variable "db_username" {
  type        = string
  description = "Usuario administrador MySQL."
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Password del usuario administrador."
  validation {
    condition     = length(var.db_password) >= 12 && can(regex("[0-9]", var.db_password)) && can(regex("[A-Za-z]", var.db_password))
    error_message = "La contraseña debe tener >=12 caracteres con letras y números."
  }
}

variable "rds_instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "Clase de instancia RDS."
}

variable "rds_engine_version" {
  type        = string
  description = "Versión de MySQL (ej: 8.0.35)."
}

variable "rds_allocated_storage" {
  type        = number
  default     = 20
  description = "Almacenamiento inicial (GB)."
}

variable "rds_max_allocated_storage" {
  type        = number
  default     = 100
  description = "Autoescalado máximo de almacenamiento (GB)."
}

variable "rds_multi_az" {
  type        = bool
  default     = true
  description = "Habilita Multi-AZ."
}

variable "rds_backup_retention_period" {
  type        = number
  default     = 7
  description = "Retención de backups automáticos (días)."
}

variable "rds_deletion_protection" {
  type        = bool
  default     = true
  description = "Protección contra borrado de RDS."
}

variable "kms_key_id" {
  type        = string
  default     = null
  description = "KMS Key para cifrado en reposo (null => default KMS)."
}
