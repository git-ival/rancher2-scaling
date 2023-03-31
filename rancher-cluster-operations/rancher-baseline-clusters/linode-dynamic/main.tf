terraform {
  required_version = ">= 0.13"
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
    }
    null = {
      source = "hashicorp/null"
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

locals {
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
  node_pool_count = length(local.roles_per_pool)
  cluster_configs = length(var.cluster_configs) == 3 ? var.cluster_configs : [
    {
      k8s_version      = "v1.25.6-rancher4-1"
      k8s_distribution = "rke1"
    },
    {
      k8s_version      = "1.25.7+rke2r1"
      k8s_distribution = "rke2"
    },
    {
      k8s_version      = "1.25.7+k3s1"
      k8s_distribution = "k3s"
    }
  ]
  v1_configs = [for i, config in local.cluster_configs : config if config.k8s_distribution == "rke1"]
  v1_count   = length(local.v1_configs)
  v2_configs = [for i, config in local.cluster_configs : config if contains(["rke2", "k3s"], config.k8s_distribution)]
  v2_count   = length(local.v2_configs)
  network_config = {
    plugin = "canal"
    mtu    = null
  }
  upgrade_strategy = {
    drain = false
  }
  kube_api = var.kube_api_debugging ? {
    extra_args = {
      v = "3"
    }
  } : null
  v1_kube_config_list = rancher2_cluster_sync.cluster_v1[*].kube_config
  v2_kube_config_list = rancher2_cluster_sync.cluster_v2[*].kube_config
  cluster_names       = concat([for cluster in module.cluster_v1 : cluster.name], [for cluster in rancher2_cluster_v2.cluster_v2 : cluster.name])
}

module "cloud_credential" {
  source     = "../../rancher-cloud-credential"
  create_new = var.create_node_reqs
  providers = {
    rancher2 = rancher2
  }

  name           = local.cloud_cred_name
  cloud_provider = "linode"
  credential_config = {
    token = var.linode_token
  }
}

module "node_template" {
  count  = local.v1_count
  source = "../../rancher-node-template"
  providers = {
    rancher2 = rancher2
  }

  create_new             = var.create_node_reqs
  name                   = "${local.node_template_name}-${count.index}"
  cloud_cred_id          = module.cloud_credential.id
  install_docker_version = var.install_docker_version
  cloud_provider         = "linode"
  node_config = {
    image            = var.image
    instance_type    = var.server_instance_type
    region           = var.region
    authorized_users = var.authorized_users
  }
  engine_fields = var.node_template_engine_fields
}

resource "rancher2_node_pool" "cluster_v1_np" {
  count                       = local.v1_count
  cluster_id                  = module.cluster_v1[count.index].id
  name                        = substr("${local.rancher_subdomain}-${local.name_suffix}-0", 0, local.name_max_length)
  hostname_prefix             = substr("${local.rancher_subdomain}-${local.name_suffix}-pool0-node", 0, local.name_max_length)
  node_template_id            = module.node_template[count.index].id
  quantity                    = try(tonumber(local.roles_per_pool[0]["quantity"]), false)
  control_plane               = try(tobool(local.roles_per_pool[0]["control-plane"]), false)
  etcd                        = try(tobool(local.roles_per_pool[0]["etcd"]), false)
  worker                      = try(tobool(local.roles_per_pool[0]["worker"]), false)
  delete_not_ready_after_secs = var.auto_replace_timeout
}

module "cluster_v1" {
  count  = local.v1_count
  source = "../../rancher-cluster/v1"
  providers = {
    rancher2 = rancher2
  }

  name               = "${local.cluster_name}${count.index}"
  description        = "TF linode nodedriver cluster ${local.cluster_name}${count.index}"
  k8s_distribution   = local.v1_configs[count.index].k8s_distribution
  k8s_version        = local.v1_configs[count.index].k8s_version
  network_config     = local.network_config
  upgrade_strategy   = local.upgrade_strategy
  kube_api           = local.kube_api
  agent_env_vars     = var.agent_env_vars
  enable_cri_dockerd = var.enable_cri_dockerd

  depends_on = [
    module.node_template
  ]
}

resource "rancher2_machine_config_v2" "this" {
  count         = local.v2_count
  generate_name = "${local.node_template_name}-${local.v2_configs[count.index].k8s_distribution}-${count.index}"
  linode_config {
    image            = var.image
    instance_type    = var.server_instance_type
    region           = var.region
    authorized_users = var.authorized_users
  }
}


resource "rancher2_cluster_v2" "cluster_v2" {
  count              = local.v2_count
  name               = "${local.cluster_name}-${local.v2_configs[count.index].k8s_distribution}-${count.index}"
  kubernetes_version = local.v2_configs[count.index].k8s_version
  rke_config {
    dynamic "machine_pools" {
      for_each = local.roles_per_pool
      iterator = pool
      content {
        name                         = substr("${local.rancher_subdomain}-${local.v2_configs[count.index].k8s_distribution}-${local.name_suffix}-0", 0, local.name_max_length)
        cloud_credential_secret_name = module.cloud_credential.id
        control_plane_role           = try(tobool(pool.value["control-plane"]), false)
        worker_role                  = try(tobool(pool.value["worker"]), false)
        etcd_role                    = try(tobool(pool.value["etcd"]), false)
        quantity                     = try(tonumber(pool.value["quantity"]), 1)

        machine_config {
          kind = rancher2_machine_config_v2.this[count.index].kind
          name = rancher2_machine_config_v2.this[count.index].name
        }
      }
    }
  }
  timeouts {
    create = "15m"
  }
  depends_on = [
    module.cloud_credential
  ]
}

resource "rancher2_cluster_sync" "cluster_v1" {
  count         = local.v1_count
  cluster_id    = module.cluster_v1[count.index].id
  node_pool_ids = [rancher2_node_pool.cluster_v1_np[count.index].id]
  state_confirm = 3
}

resource "rancher2_cluster_sync" "cluster_v2" {
  count         = local.v2_count
  cluster_id    = rancher2_cluster_v2.cluster_v2[count.index].cluster_v1_id
  state_confirm = 3
}

resource "local_file" "v1_kube_config" {
  count           = length(local.v1_kube_config_list)
  content         = local.v1_kube_config_list[count.index]
  filename        = "${path.module}/files/kube_config/${terraform.workspace}_${module.cluster_v1[count.index].name}_kube_config"
  file_permission = "0700"
}

resource "local_file" "v2_kube_config" {
  count           = length(local.v2_kube_config_list)
  content         = local.v2_kube_config_list[count.index]
  filename        = "${path.module}/files/kube_config/${terraform.workspace}_${rancher2_cluster_v2.cluster_v2[count.index].name}_kube_config"
  file_permission = "0700"
}

module "cluster1_bulk_components" {
  for_each = toset(local.cluster_names)
  source   = "../../bulk-components"
  providers = {
    rancher2 = rancher2
  }
  rancher_api_url   = var.rancher_api_url
  rancher_token_key = var.rancher_token_key
  output_local_file = false

  cluster_name         = each.value
  num_projects         = 10
  num_namespaces       = 12
  num_secrets          = 100
  num_users            = 300
  name_prefix          = "baseline-${each.value}"
  user_project_binding = true
  user_password        = "Ranchertest1234!"

  depends_on = [
    rancher2_cluster_sync.cluster_v1,
    rancher2_cluster_sync.cluster_v2
  ]
}

# module "cluster2_bulk_components" {
#   source = "../../bulk-components"
#   providers = {
#     rancher2 = rancher2
#   }
#   rancher_api_url   = var.rancher_api_url
#   rancher_token_key = var.rancher_token_key
#   output_local_file = false

#   cluster_name         = module.cluster_v1[1].name
#   num_projects         = 10
#   num_namespaces       = 12
#   num_secrets          = 100
#   num_users            = 300
#   name_prefix          = "baseline-${module.cluster_v1[1].name}"
#   user_project_binding = false
#   user_password        = "Ranchertest1234!"

#   depends_on = [
#     rancher2_cluster_sync.cluster2
#   ]
# }

# module "cluster3_bulk_components" {
#   source = "../../bulk-components"
#   providers = {
#     rancher2 = rancher2
#   }
#   rancher_api_url   = var.rancher_api_url
#   rancher_token_key = var.rancher_token_key
#   output_local_file = false

#   cluster_name         = module.cluster_v1[2].name
#   num_projects         = 10
#   num_namespaces       = 12
#   num_secrets          = 100
#   num_users            = 300
#   name_prefix          = "baseline-${module.cluster_v1[2].name}"
#   user_project_binding = false
#   user_password        = "Ranchertest1234!"

#   depends_on = [
#     rancher2_cluster_sync.cluster3
#   ]
# }

output "create_node_reqs" {
  value = var.create_node_reqs
}

output "cred_name" {
  value = module.cloud_credential.name
}

output "nt_names" {
  value = concat(module.node_template[*].name, rancher2_machine_config_v2.this[*].name)
}

output "cluster_names" {
  value = concat(module.cluster_v1[*].name, rancher2_cluster_v2.cluster_v2[*].name)
}

# output "kube_config" {
#   value = nonsensitive(module.cluster_v1.kube_config)
# }
