variable "subnet_id" {}
variable "security_group_id" {}
variable "ssh_allowed_cidr" {
  type    = string
  default = "203.0.113.0/32" # reemplaza por tu IP/publica/32
}