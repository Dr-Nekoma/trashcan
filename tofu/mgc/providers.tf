terraform {
  required_providers {
    mgc = {
      source  = "magalucloud/mgc"
      version = "~> 0.27"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "mgc" {
  alias  = "sudeste"
  region = var.mgc_region
  api_key = var.mgc_api_key
}
