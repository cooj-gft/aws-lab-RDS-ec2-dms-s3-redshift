variable "name_prefix" {
  type        = string
  description = "Prefijo para nombrar la instancia RDS."
}

variable "db_subnet_group_name" {
  type        = string
  description = "DB Subnet Group (privado) para la RDS."
}

variable "rds_sg_id" {
  type        = string
  description = "Security Group a asociar a la RDS."
}

variable "db_name" {
  type = string
  description = "Nombre de la base inicial."
}

variable "db_username" {
  type = string
  description = "Usuario admin."
}

variable "db_password" {
  type      = string
  sensitive = true
  description = "Password admin (sensible)."
}

variable "instance_class" {
  type        = string
  description = "Clase de instancia RDS."
}

variable "engine_version" {
  type        = string
  description = "Versión de MySQL."
}

variable "allocated_storage" {
  type        = number
  description = "Almacenamiento inicial (GB)."
}

variable "max_allocated_storage" {
  type        = number
  description = "Autoescalado máximo de almacenamiento (GB)."
}

variable "multi_az" {
  type        = bool
  description = "Habilitar Multi-AZ."
}

variable "backup_retention_days" {
  type        = number
  description = "Retención de backups automáticos (días)."
}

variable "deletion_protection" {
  type        = bool
  description = "Protección contra borrado."
}

variable "kms_key_id" {
  type        = string
  default     = null
  description = "KMS Key para cifrado en reposo (null => default)."
}

variable "apply_immediately" {
  type        = bool
  default     = true
  description = "Aplicar cambios inmediatamente."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Etiquetas comunes."
}
