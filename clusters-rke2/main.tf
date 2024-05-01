terraform {
  required_version = ">= 0.13"
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      version = ">= 2.0.0, <= 5.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.22.0"
    }
    random = {
      source = "hashicorp/random"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

terraform {
  backend "local" {
  }
}

provider "rancher2" {
  api_url   = var.rancher_api_url
  token_key = var.rancher_token_key
  insecure  = var.insecure_flag
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "random_id" "index" {
  byte_length = 2
}

locals {
  az_zone_ids_list         = tolist(data.aws_availability_zones.available.zone_ids)
  az_zone_ids_random_index = random_id.index.dec % length(local.az_zone_ids_list)
  instance_az_zone_id      = local.az_zone_ids_list[local.az_zone_ids_random_index]
  selected_az_suffix       = data.aws_availability_zone.selected_az.name_suffix
  subnet_ids_list          = tolist(data.aws_subnets.available.ids)
  subnet_ids_random_index  = random_id.index.dec % length(local.subnet_ids_list)
  instance_subnet_id       = local.subnet_ids_list[local.subnet_ids_random_index]
  ssh_key_path_valid       = try(var.ssh_key_path != null && length(var.ssh_key_path) > 0, false)
  create_private_key       = !local.ssh_key_path_valid ? true : false
  rancher_subdomain        = split(".", split("//", "${var.rancher_api_url}")[1])[0]
  public_key_path_valid    = try(var.public_key_path != null && length(var.public_key_path) > 0, false)
  public_key               = local.public_key_path_valid && local.create_private_key ? file(var.public_key_path) : trimspace(tls_private_key.node_key[0].public_key_openssh)
  ssh_key_contents         = local.ssh_key_path_valid && local.create_private_key ? file(var.ssh_key_path) : trimspace(tls_private_key.node_key[0].private_key_openssh)
  cloud_cred_name          = length(var.cloud_cred_name) > 0 ? var.cloud_cred_name : "${local.rancher_subdomain}-${local.name_suffix}-aws-cloud-cred"
  security_groups          = [for group in data.aws_security_group.selected : group.name]
  name_max_length          = 60
  name_suffix              = length(var.name_suffix) > 0 ? var.name_suffix : "rke2-${terraform.workspace}"
  machine_pool_name        = substr("np", 0, local.name_max_length)
  cluster_name             = length(var.cluster_name) > 0 ? var.cluster_name : "${substr("${local.rancher_subdomain}-${local.name_suffix}", 0, local.name_max_length)}"
}

resource "rancher2_cloud_credential" "shared_cred" {
  count = var.create_credential ? 1 : 0

  name = local.cloud_cred_name
  amazonec2_credential_config {
    access_key     = var.aws_access_key
    secret_key     = var.aws_secret_key
    default_region = var.aws_region
  }
}

resource "tls_private_key" "node_key" {
  count     = local.create_private_key ? 1 : 0
  algorithm = "RSA"
}

resource "rancher2_machine_config_v2" "aws" {
  generate_name = local.machine_pool_name
  amazonec2_config {
    ami                  = data.aws_ami.ubuntu.id
    region               = var.aws_region
    security_group       = local.security_groups
    subnet_id            = local.instance_subnet_id
    vpc_id               = data.aws_vpc.default.id
    zone                 = local.selected_az_suffix
    iam_instance_profile = var.iam_instance_profile
    instance_type        = var.server_instance_type
    ssh_user             = "ubuntu"
    # ssh_key_contents     = local.ssh_key_contents
    tags        = "RancherScaling,${local.rancher_subdomain}-${local.name_suffix},Owner,${local.rancher_subdomain}-${local.name_suffix},DoNotDelete,true"
    volume_type = var.volume_type
    root_size   = var.volume_size
  }
}

resource "rancher2_cluster_v2" "rke2" {
  name                                                       = local.cluster_name
  labels                                                     = var.cluster_labels
  kubernetes_version                                         = var.k8s_version
  default_pod_security_admission_configuration_template_name = var.psa_config

  rke_config {
    dynamic "machine_pools" {
      for_each = var.roles_per_pool
      iterator = pool
      content {
        name                         = "${local.rancher_subdomain}-${local.name_suffix}${pool.key}"
        cloud_credential_secret_name = data.rancher2_cloud_credential.this.id
        control_plane_role           = try(tobool(pool.value["control-plane"]), false)
        worker_role                  = try(tobool(pool.value["worker"]), false)
        etcd_role                    = try(tobool(pool.value["etcd"]), false)
        quantity                     = try(tonumber(pool.value["quantity"]), 1)

        machine_config {
          kind = rancher2_machine_config_v2.aws.kind
          name = rancher2_machine_config_v2.aws.name
        }
      }
    }
  }

  timeouts {
    create = "40m"
  }

  depends_on = [
    data.rancher2_cloud_credential.this
  ]
}

resource "local_file" "kube_config" {
  content  = nonsensitive(rancher2_cluster_v2.rke2.kube_config)
  filename = "${path.module}/files/kube_config/${terraform.workspace}_kube_config"
}
