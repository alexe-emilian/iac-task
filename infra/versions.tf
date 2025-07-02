terraform {
  # Pin at least Terraform 1.8 to avoid unexpected syntax changes in old
  # versions shipped by default on some CI runners.
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"  # minor bumps for new resources, but no breaking changes
    }
  }
}
