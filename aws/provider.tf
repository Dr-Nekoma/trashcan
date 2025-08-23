terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.10.0"
    }
  }
}

# Configuration options
provider "aws" {
  profile = "nekoma"
  region  = var.region
}
