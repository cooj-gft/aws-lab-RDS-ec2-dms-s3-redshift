terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 6.13" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      stack_id   = var.stack_id
      repository = var.repository_url
      sponsor    = var.sponsor
      cod_app    = "519"
    }
  }
}