terraform {
  required_version = ">= 0.14"
  required_providers {
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.2.0, <= 3.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2.3, <= 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3, <= 4.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.1, <= 4.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7.1, <= 3.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.46.0, <= 5.0.0"
    }
    linode = {
      source  = "linode/linode"
      version = ">= 1.30.0, <= 2.0.0"
    }
    rke = {
      source  = "rancher/rke"
      version = ">= 1.3.4, <= 2.0.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = ">= 2.0.0, <= 3.0.0"
    }
  }
  backend "local" {
    path = "rancher.tfstate"
  }
}

provider "aws" {
  region  = var.infra_provider == "aws" ? local.region : ""
  profile = "rancher-eng"
}

provider "linode" {
  token = var.linode_token
}

provider "rancher2" {
  alias     = "bootstrap"
  api_url   = "https://${local.name}.${local.domain}"
  insecure  = false
  bootstrap = true
}

provider "helm" {
  kubernetes {
    config_path = abspath(local.kube_config)
  }
}

provider "rancher2" {
  alias     = "admin"
  api_url   = local.rancher_url
  token_key = local.rancher_token
  insecure  = false
  timeout   = "300s"
}
