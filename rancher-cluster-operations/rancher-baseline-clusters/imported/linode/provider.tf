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

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "rancher2" {
  api_url   = var.rancher_api_url
  token_key = var.rancher_token_key
  insecure  = var.insecure_flag
}
