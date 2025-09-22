variable "name_prefix" {
  type        = string
  description = "Prefijo para nombrar recursos de red."
}

variable "vpc_id" {
  type        = string
  description = "VPC a utilizar."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Subredes privadas para RDS (DB Subnet Group)."
}

variable "allowed_ssh_sg_ids" {
  type        = list(string)
  default     = []
  description = "SGs autorizadas a hacer SSH a la EC2."
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDRs autorizadas para SSH (no 0.0.0.0/0)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Etiquetas comunes."
}
