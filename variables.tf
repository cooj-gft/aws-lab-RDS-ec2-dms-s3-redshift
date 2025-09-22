variable "aws_region" {
  type        = string
  description = "Región AWS (ej: us-east-1)."
}
variable "stack_id" {
  description = "The stack identifier"
  type        = string
}
variable "repository_url" {
  description = "The URL of the repository"
  type        = string
}
variable "sponsor" {
  description = "The sponsor for tagging AWS resources"
  type        = string
}
variable "name_prefix" {
  type        = string
  description = "Prefijo para nombrar recursos (org-app-env)."
}

variable "tags" {
  type        = map(string)
  description = "Etiquetas comunes."
  default     = {}
}

# --- Parámetros de red (como ahora creamos la VPC)
variable "vpc_cidr" {
  type        = string
  description = "CIDR de la VPC (ej: 10.0.0.0/16)."
}

variable "az_count" {
  type        = number
  description = "Número de AZs a utilizar (>=2 recomendado)."
  default     = 2
}

variable "public_subnet_newbits" {
  type        = number
  default     = 8         # /24 si VPC es /16
  description = "newbits para cidrsubnet() de subredes públicas."
}

variable "private_subnet_newbits" {
  type        = number
  default     = 8         # /24 si VPC es /16
  description = "newbits para cidrsubnet() de subredes privadas."
}

variable "enable_nat_gateway" {
  type        = bool
  default     = true
  description = "Crea NAT Gateway para salida a Internet desde privadas."
}

variable "single_nat_gateway" {
  type        = bool
  default     = true
  description = "true = 1 NAT (coste bajo), false = NAT por AZ (alta disp.)."
}

variable "enable_ssm_endpoints" {
  type        = bool
  default     = false
  description = "Crear VPC Endpoints (Interface) para SSM/EC2Messages/SSMMessages."
}

# --- SSH restringido
variable "allowed_ssh_sg_ids" {
  type        = list(string)
  default     = []
  description = "SGs autorizadas para SSH hacia la EC2."
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDRs autorizadas para SSH (no 0.0.0.0/0)."
}

# --- EC2
variable "ec2_instance_type" {
  type        = string
  default     = "t3.micro"
}

variable "ec2_ami_id" {
  type        = string
  default     = null
  description = "AMI ID. Si null, se resuelve por SSM (Amazon Linux 2023)."
}

variable "ec2_ami_ssm_parameter_path" {
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "ec2_key_name" {
  type        = string
  default     = null
  description = "Par de llaves SSH (opcional si usas SSM)."
}

variable "enable_ssm" {
  type        = bool
  default     = true
  description = "Adjunta rol AmazonSSMManagedInstanceCore a la EC2."
}

# --- RDS MySQL
variable "db_name"       { type = string }
variable "db_username"   { type = string }
variable "db_password"   {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.db_password) >= 12 && can(regex("[0-9]", var.db_password)) && can(regex("[A-Za-z]", var.db_password))
    error_message = ">=12 chars, con letras y números."
  }
}

variable "rds_instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "Clase de instancia RDS (ej.: db.t3.micro, db.t3.small)."
}

variable "rds_engine_version" {
  type        = string
  description = "Versión del motor RDS (ej.: 8.0.35)."
}

variable "rds_allocated_storage" {
  type        = number
  default     = 20
  description = "Almacenamiento asignado para la base de datos (GB)."
}

variable "rds_max_allocated_storage" {
  type        = number
  default     = 100
  description = "Almacenamiento máximo asignado para la base de datos (GB)."
}

variable "rds_multi_az" {
  type        = bool
  default     = true
  description = "Habilita la implementación Multi-AZ para alta disponibilidad."
}

variable "rds_backup_retention_days" {
  type        = number
  default     = 7
  description = "Número de días para retener copias de seguridad."
}
variable "rds_deletion_protection" {
  type        = bool
  default     = true
  description = "Protección contra eliminación de la instancia RDS (true evita borrado accidental)."
}

variable "kms_key_id" {
  type        = string
  default     = null
  description = "ID/ARN de la clave KMS usada para cifrado. Si es null se usa la clave gestionada por AWS."
}