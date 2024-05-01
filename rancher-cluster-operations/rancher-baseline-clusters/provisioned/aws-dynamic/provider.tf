terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.63.0, <= 6.0.0"
    }
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
