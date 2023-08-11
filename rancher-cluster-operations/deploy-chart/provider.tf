terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = abspath(var.kube_config_path)
  }
  experiments {
    manifest = true
  }
}
