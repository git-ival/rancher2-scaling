terraform {
  required_version = ">= 1.3"
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      version = ">= 2.0.0"
    }
  }
  backend "local" {
    path = "rancher.tfstate"
  }
}

# provider "rancher2" {
#   api_url   = var.rancher_url
#   token_key = var.rancher_token
# }
