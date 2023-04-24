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
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.46.0, <= 5.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.6.0, <= 3.0.0"
    }
    rke = {
      source  = "rancher/rke"
      version = ">= 1.3.0, <= 2.0.0"
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
  region  = local.aws_region
  profile = "rancher-eng"
}

provider "aws" {
  region  = local.aws_region
  profile = "rancher-eng"
  alias   = "r53"
}

provider "rancher2" {
  alias     = "bootstrap"
  api_url   = "https://${local.name}.${local.domain}"
  insecure  = length(var.byo_certs_bucket_path) > 0 ? true : false
  bootstrap = true
}

provider "rke" {
  debug = true
  # log_file = var.k8s_distribution == "rke1" ? "${path.module}/files/${local.name}_${terraform.workspace}_rke1_logs.txt" : null
}

provider "helm" {
  kubernetes {
    config_path = abspath(module.generate_kube_config.kubeconfig_path)
  }
}

provider "rancher2" {
  alias     = "admin"
  api_url   = local.rancher_url
  token_key = local.rancher_token
  insecure  = length(var.byo_certs_bucket_path) > 0 ? true : false
  timeout   = "300s"
}
