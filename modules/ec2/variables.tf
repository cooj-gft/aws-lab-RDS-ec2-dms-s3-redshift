variable "name_prefix" {
  type        = string
  description = "Prefijo para la EC2."
}

variable "subnet_id" {
  type        = string
  description = "Subred privada donde desplegar la EC2."
}

variable "ec2_sg_id" {
  type        = string
  description = "Security Group a asociar a la EC2."
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia."
}

variable "ami_id" {
  type        = string
  default     = null
  description = "AMI ID. Si es null, se resolverá por SSM."
}

variable "ami_ssm_parameter_path" {
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  description = "Parámetro SSM de la AMI a usar si ami_id es null."
}

variable "key_name" {
  type        = string
  default     = null
  description = "Par de llaves para SSH."
}

variable "enable_ssm" {
  type        = bool
  default     = true
  description = "Crea IAM role/profile para SSM."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Etiquetas comunes."
}
