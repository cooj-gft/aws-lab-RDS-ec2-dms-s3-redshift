variable "name_prefix"        { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "db_name"            { type = string }
variable "db_username"        { type = string }
variable "db_password"        { type = string }
variable "instance_class"     { type = string }
variable "common_tags"        { type = map(string) }
variable "ingress_sg_ids"     { type = list(string)  default = [] }
  
}
