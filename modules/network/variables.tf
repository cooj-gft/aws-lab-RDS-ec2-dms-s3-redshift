variable "name_prefix" {
  type        = string
  description = "Prefijo usado para nombrar recursos (ej. 'mi-proyecto')."
}

variable "vpc_cidr" {
  type        = string
  description = "Rango CIDR de la VPC principal (ej. '10.0.0.0/16')."
}

variable "az_count" {
  type        = number
  description = "Número de zonas de disponibilidad a usar para crear subredes."
}

variable "public_subnet_newbits" {
  type        = number
  description = "Bits adicionales para calcular el tamaño de las subredes públicas (más bits = subredes más pequeñas)."
}

variable "private_subnet_newbits" {
  type        = number
  description = "Bits adicionales para calcular el tamaño de las subredes privadas."
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Habilita la creación de NAT Gateway(s) para dar salida a Internet a subredes privadas."
}

variable "single_nat_gateway" {
  type        = bool
  description = "Si es true, crea un solo NAT Gateway compartido entre AZs (ahorro de costo vs alta disponibilidad)."
}

variable "enable_ssm_endpoints" {
  type        = bool
  description = "Crear endpoints VPC para AWS Systems Manager (permite que instancias accedan a SSM sin salir a Internet)."
}

variable "allowed_ssh_sg_ids" {
  type        = list(string)
  default     = []
  description = "Lista de IDs de security groups que se permitirán para SSH (usar referencias a SG en lugar de CIDR cuando sea posible)."
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  default     = []
  description = "Lista de CIDR que podrán conectarse por SSH (ej. ['203.0.113.4/32']). Restringir a /32 en producción."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Mapa de tags que se aplicarán a los recursos creados por este módulo."
}