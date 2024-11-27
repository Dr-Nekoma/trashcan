terraform {
  required_providers {
    mgc = {
      source = "registry.terraform.io/magalucloud/mgc"
    }
  }
}

provider "mgc" {
  alias   = "se"
  region  = var.region
  api_key = var.api_key
}

