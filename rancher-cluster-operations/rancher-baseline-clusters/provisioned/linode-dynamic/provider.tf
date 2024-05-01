terraform {
  required_version = ">= 1.3"
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      version = ">= 2.0.0, <= 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3, <= 4.0.0"
    }
  }
  backend "local" {
    path = "rancher.tfstate"
  }
}

provider "rancher2" {
  api_url   = var.rancher_api_url
  token_key = var.rancher_token_key
  insecure  = var.insecure_flag
}
