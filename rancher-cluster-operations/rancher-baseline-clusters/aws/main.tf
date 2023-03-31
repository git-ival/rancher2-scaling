terraform {
  required_version = ">= 0.13"
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
    }
    null = {
      source = "hashicorp/null"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

terraform {
  backend "local" {
    path = "rancher.tfstate"
  }
}

provider "rancher2" {
  api_url   = var.rancher_api_url
  token_key = var.rancher_token_key
  insecure  = var.insecure_flag
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

  name_max_length    = 60
  rancher_subdomain  = split(".", split("//", "${var.rancher_api_url}")[1])[0]
  name_suffix        = length(var.name_suffix) > 0 ? var.name_suffix : "${terraform.workspace}"
  cloud_cred_name    = length(var.cloud_cred_name) > 0 ? var.cloud_cred_name : "${local.rancher_subdomain}-cloud-cred-${local.name_suffix}"
  node_template_name = length(var.node_template_name) > 0 ? var.node_template_name : "${local.rancher_subdomain}-${local.name_suffix}"
  node_pool_name     = substr("${local.rancher_subdomain}-nt${local.name_suffix}", 0, local.name_max_length)
  cluster_name       = length(var.cluster_name) > 0 ? var.cluster_name : "${substr("${local.rancher_subdomain}-${local.name_suffix}", 0, local.name_max_length)}"
  roles_per_pool = [
    {
      "quantity"      = 3
      "etcd"          = true
      "control-plane" = true
      "worker"        = true
    }
  ]
  # network_config = {
  #   plugin = "canal"
  #   mtu    = null
  # }
  # upgrade_strategy = {
  #   drain = false
  # }
  # kube_api = var.kube_api_debugging ? {
  #   extra_args = {
  #     v = "3"
  #   }
  # } : null
  # rke1_kube_config = rancher2_cluster_sync.rke1.kube_config
  # rke2_kube_config = rancher2_cluster_sync.rke2.kube_config
  # k3s_kube_config  = rancher2_cluster_sync.k3s.kube_config
  cluster_names = [rancher2_cluster_v2.rke2.name]
}

# module "cloud_credential" {
#   source     = "../../rancher-cloud-credential"
#   create_new = var.create_node_reqs
#   providers = {
#     rancher2 = rancher2
#   }

#   name           = local.cloud_cred_name
#   cloud_provider = "linode"
#   credential_config = {
#     token = var.linode_token
#   }
# }

resource "rancher2_cloud_credential" "shared_cred" {
  count = var.create_node_reqs ? 1 : 0

  name = local.cloud_cred_name
  amazonec2_credential_config {
    access_key     = var.aws_access_key
    secret_key     = var.aws_secret_key
    default_region = var.region
  }
  # linode_credential_config {
  #   token = var.linode_token
  # }
}

data "rancher2_cloud_credential" "this" {
  # name = var.create_node_reqs ? module.cloud_credential.name : local.cloud_cred_name
  name = var.create_node_reqs ? rancher2_cloud_credential.shared_cred[0].name : local.cloud_cred_name
}

# module "node_template" {
#   source = "../../rancher-node-template"
#   providers = {
#     rancher2 = rancher2
#   }

#   create_new             = var.create_node_reqs
#   name                   = local.node_template_name
#   cloud_cred_id          = module.cloud_credential.id
#   install_docker_version = var.install_docker_version
#   cloud_provider         = "linode"
#   node_config = {
#     image            = var.image
#     instance_type    = var.server_instance_type
#     region           = var.region
#     authorized_users = var.authorized_users
#   }
#   engine_fields = var.node_template_engine_fields
# }

# resource "rancher2_node_pool" "this" {
#   cluster_id                  = module.rke1.id
#   name                        = substr("${local.rancher_subdomain}-${local.name_suffix}-0", 0, local.name_max_length)
#   hostname_prefix             = substr("${local.rancher_subdomain}-${local.name_suffix}-pool0-node", 0, local.name_max_length)
#   node_template_id            = module.node_template.id
#   quantity                    = try(tonumber(local.roles_per_pool[0]["quantity"]), false)
#   control_plane               = try(tobool(local.roles_per_pool[0]["control-plane"]), false)
#   etcd                        = try(tobool(local.roles_per_pool[0]["etcd"]), false)
#   worker                      = try(tobool(local.roles_per_pool[0]["worker"]), false)
#   delete_not_ready_after_secs = var.auto_replace_timeout
# }

# module "rke1" {
#   source = "../../rancher-cluster/v1"
#   providers = {
#     rancher2 = rancher2
#   }

#   name               = "${local.cluster_name}-rke1"
#   description        = "TF linode nodedriver cluster ${local.cluster_name}-rke1"
#   k8s_distribution   = "rke1"
#   k8s_version        = var.rke1_version
#   network_config     = local.network_config
#   upgrade_strategy   = local.upgrade_strategy
#   kube_api           = local.kube_api
#   agent_env_vars     = var.agent_env_vars
#   enable_cri_dockerd = var.enable_cri_dockerd
#   # sensitive_output   = false

#   depends_on = [
#     module.node_template
#   ]
# }

resource "rancher2_machine_config_v2" "this" {
  generate_name = "cluster-v2-machine-config"
  amazonec2_config {
    ami            = data.aws_ami.ubuntu.id
    region         = var.region
    security_group = ["open-all"]
    subnet_id      = local.instance_subnet_id
    vpc_id         = data.aws_vpc.default.id
    zone           = local.selected_az_suffix
    instance_type  = var.server_instance_type
    tags           = "RancherScaling,${var.cluster_name},Owner,${var.cluster_name}"
    volume_type    = var.volume_type
    root_size      = var.volume_size
  }
  # linode_config {
  #   image            = var.image
  #   instance_type    = var.server_instance_type
  #   region           = var.region
  #   authorized_users = var.authorized_users
  # }
}

resource "rancher2_cluster_v2" "rke2" {
  name               = "rke2"
  kubernetes_version = var.rke2_version
  rke_config {
    machine_pools {
      name = "pool1"
      # cloud_credential_secret_name = module.cloud_credential.id
      # cloud_credential_secret_name = local.cloud_cred_name
      cloud_credential_secret_name = data.rancher2_cloud_credential.this.id
      control_plane_role           = true
      worker_role                  = true
      etcd_role                    = true
      quantity                     = 3
      machine_config {
        kind = rancher2_machine_config_v2.this.kind
        name = rancher2_machine_config_v2.this.name
      }
    }
  }

  timeouts {
    create = "15m"
  }

  depends_on = [
    # module.cloud_credential,
    data.rancher2_cloud_credential.this
  ]
}

# resource "rancher2_cluster_v2" "k3s" {
#   name               = "${local.cluster_name}-k3s"
#   kubernetes_version = var.k3s_version
#   rke_config {
#     dynamic "machine_pools" {
#       for_each = local.roles_per_pool
#       iterator = pool
#       content {
#         name                         = substr("${local.rancher_subdomain}-k3s-${local.name_suffix}-0", 0, local.name_max_length)
#         cloud_credential_secret_name = module.cloud_credential.id
#         # cloud_credential_secret_name = local.cloud_cred_name
#         control_plane_role = true
#         worker_role        = true
#         etcd_role          = true
#         quantity           = 3
#         machine_config {
#           kind = rancher2_machine_config_v2.this.kind
#           name = rancher2_machine_config_v2.this.name
#         }
#       }
#     }
#   }

#   timeouts {
#     create = "15m"
#   }

#   depends_on = [
#     module.cloud_credential
#   ]
# }

# resource "rancher2_cluster_sync" "rke1" {
#   cluster_id    = module.rke1.id
#   node_pool_ids = [rancher2_node_pool.this.id]
#   state_confirm = 3
# }

# resource "rancher2_cluster_sync" "rke2" {
#   cluster_id    = rancher2_cluster_v2.rke2.cluster_v1_id
#   state_confirm = 3
# }

# resource "rancher2_cluster_sync" "k3s" {
#   cluster_id    = rancher2_cluster_v2.k3s.cluster_v1_id
#   state_confirm = 3
# }

# resource "local_file" "rke1_kube_config" {
#   content         = local.rke1_kube_config
#   filename        = "${path.module}/files/kube_config/${terraform.workspace}_${module.rke1.name}_kube_config"
#   file_permission = "0700"
# }

resource "local_file" "rke2" {
  content         = rancher2_cluster_v2.rke2.kube_config
  filename        = "${path.module}/files/kube_config/${terraform.workspace}_${rancher2_cluster_v2.rke2.name}_kube_config"
  file_permission = "0700"
}

# resource "local_file" "k3s" {
#   content         = rancher2_cluster_v2.k3s.kube_config
#   filename        = "${path.module}/files/kube_config/${terraform.workspace}_${rancher2_cluster_v2.k3s.name}_kube_config"
#   file_permission = "0700"
# }


# module "cluster1_bulk_components" {
#   for_each = toset(local.cluster_names)
#   source   = "../../bulk-components"
#   providers = {
#     rancher2 = rancher2
#   }
#   rancher_api_url   = var.rancher_api_url
#   rancher_token_key = var.rancher_token_key
#   output_local_file = false

#   cluster_name         = each.value
#   num_projects         = 10
#   num_namespaces       = 12
#   num_secrets          = 100
#   num_users            = 300
#   name_prefix          = "baseline-${each.value}"
#   user_project_binding = true
#   user_password        = "Ranchertest1234!"

#   depends_on = [
#     # rancher2_cluster_sync.rke1,
#     rancher2_cluster_v2.rke2
#     # rancher2_cluster_v2.k3s
#   ]
# }

output "create_node_reqs" {
  value = var.create_node_reqs
}

output "cred_name" {
  value = local.cloud_cred_name
}

# output "nt_names" {
#   value = [module.node_template.name, rancher2_machine_config_v2.this.name]
# }

output "cluster_names" {
  value = local.cluster_names
}

# output "kube_config" {
#   value = nonsensitive(module.cluster_v1.kube_config)
# }
