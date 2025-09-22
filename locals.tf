locals {
  common_tags = merge(
    {
      "Project"     = var.name_prefix
      "ManagedBy"   = "Terraform"
    },
    var.tags
  )
}
