terraform {
  required_version = ">= 0.13"
  required_providers {
    linode = {
      source  = "linode/linode"
      version = ">= 1.30.0, <= 2.0.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = ">= 2.0.0, <= 4.0.0"
    }
  }
  backend "local" {
    path = "rancher.tfstate"
  }
}

provider "linode" {
  # config_path    = var.linode_config_path
  # config_profile = var.linode_config_profile
  token = var.linode_token
}

provider "rancher2" {
  api_url   = var.rancher_api_url
  token_key = var.rancher_token_key
  insecure  = var.insecure_flag
}
