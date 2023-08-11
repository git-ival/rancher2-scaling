locals {
  ### Naming
  name_max_length      = 60
  rancher_subdomain    = split(".", split("//", "${var.rancher_api_url}")[1])[0]
  name_suffix          = length(var.name_suffix) > 0 ? var.name_suffix : "${terraform.workspace}"
  cloud_cred_name      = length(var.cloud_cred_name) > 0 ? var.cloud_cred_name : "${local.rancher_subdomain}-cloud-cred-${local.name_suffix}"
  provision_components = var.num_projects > 0 || var.num_namespaces > 0 || var.num_secrets > 0 || var.num_users > 0
  ### Misc Defaults
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
  ### Cluster and node pool configuration
  cluster_configs = [for i, config in var.cluster_configs : {
    name             = length(config.name) > 0 ? config.name : substr("${config.k8s_distribution}-${local.name_suffix}${i}", 0, local.name_max_length)
    k8s_distribution = config.k8s_distribution
    k8s_version      = config.k8s_version
    psa_config       = config.psa_config
    roles_per_pool   = config.roles_per_pool
  }]
  v1_configs = {
    for i, config in local.cluster_configs :
    i => config if config.k8s_distribution == "rke1"
  }
  v1_pools = flatten([
    for config_key, config in local.v1_configs : [
      for pool_key, pool in config.roles_per_pool : {
        config_key      = config_key
        pool_key        = pool_key
        name            = substr("${config.name}-pool${pool_key}", 0, local.name_max_length)
        hostname_prefix = substr("${config.name}-pool${pool_key}-node", 0, local.name_max_length)
        quantity        = pool.quantity
        etcd            = pool.etcd
        control-plane   = pool.control-plane
        worker          = pool.worker
        labels          = pool.labels
        taints          = pool.taints
      }
    ]
  ])
  fleet_affinity_override = jsonencode({
    nodeAffinity = {
      preferredDuringSchedulingIgnoredDuringExecution = [{
        preference = {
          matchExpressions = [{
            key      = "fleet.cattle.io/agent"
            operator = "In"
            values   = ["true", ]
          }, ]
        }
        weight = 1
      }, ]
      requiredDuringSchedulingIgnoredDuringExecution = {
        nodeSelectorTerms = [{
          matchExpressions = [{
            key      = "fleet"
            operator = "Exists"
          }, ]
        }, ]
      }
    }
  })
  v1_fleet_pool = [for i, pool in local.v1_pools.* : pool if contains(keys(pool.labels), "fleet")] # there should only ever be 1
  v1_fleet_customization = length(local.v1_fleet_pool) > 0 ? [{
    append_tolerations = [for taint in local.v1_fleet_pool[0].taints.* : taint if taint != null]
    override_affinity  = length(local.v1_fleet_pool) > 0 ? local.fleet_affinity_override : null
  }] : []
  v1_count = length(keys(local.v1_configs))
  v2_configs = {
    for i, config in local.cluster_configs :
    i => config if contains(["rke2", "k3s"], config.k8s_distribution)
  }
  v2_pools      = flatten([for config in local.v2_configs : [for pool in config.roles_per_pool : pool]])
  v2_fleet_pool = [for i, pool in local.v2_pools.* : pool if contains(keys(pool.labels), "fleet")] # there should only ever be 1
  v2_fleet_customization = length(local.v2_fleet_pool) > 0 ? [{
    append_tolerations = [for taint in local.v2_fleet_pool[0].taints.* : taint if taint != null]
    override_affinity  = length(local.v2_fleet_pool) > 0 ? local.fleet_affinity_override : null
  }] : []
  v2_count            = length(keys(local.v2_configs))
  v1_kube_config_list = rancher2_cluster_sync.cluster_v1[*].kube_config
  v2_kube_config_list = rancher2_cluster_sync.cluster_v2[*].kube_config
  v1_clusters         = values(module.cluster_v1)
  v2_clusters         = values(rancher2_cluster_v2.cluster_v2)
  clusters            = concat(local.v1_clusters[*], local.v2_clusters[*])
  clusters_info = {
    for i, cluster in local.clusters :
    i => {
      id      = try(cluster.cluster_v1_id, cluster.id)
      name    = cluster.name
      project = "baseline-components"
    }
  }
}

module "cloud_credential" {
  source     = "../../../rancher-cloud-credential"
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

resource "rancher2_project" "this" {
  for_each   = local.clusters_info
  cluster_id = each.value.id
  name       = each.value.project
  depends_on = [
    rancher2_cluster_sync.cluster_v1,
    rancher2_cluster_sync.cluster_v2
  ]
}

# resource "rancher2_catalog_v2" "rancher_charts_custom" {
#   for_each = local.clusters_info
#   provider = rancher2

#   cluster_id = each.value.id
#   name       = "rancher-charts-custom"
#   git_repo   = "https://git.rancher.io/charts"
#   git_branch = "dev-v2.7"

#   provisioner "local-exec" {
#     command = <<-EOT
#     sleep 10
#     EOT
#   }

#   depends_on = [
#     rancher2_project.this
#   ]
# }

# resource "rancher2_app_v2" "rancher_monitoring" {
#   for_each = local.clusters_info
#   provider = rancher2

#   cluster_id    = each.value.id
#   name          = "rancher-monitoring"
#   namespace     = "cattle-monitoring-system"
#   repo_name     = "rancher-charts-custom"
#   chart_name    = "rancher-monitoring"
#   chart_version = "102.0.1+up40.1.2"
#   values        = file("/home/ivln/workspace/work/RancherVCS/rancher2-scaling/rancher-cluster-operations/charts/rancher-monitoring/files/rancher_monitoring_chart_values.yaml")

#   depends_on = [
#     rancher2_catalog_v2.rancher_charts_custom
#   ]
# }

module "rancher_monitoring" {
  for_each = var.install_monitoring == true ? local.clusters_info : {}
  source   = "../../../charts/rancher-monitoring"
  providers = {
    rancher2 = rancher2
  }

  use_v2        = true
  rancher_url   = var.rancher_api_url
  rancher_token = var.rancher_token_key
  charts_branch = var.rancher_charts_branch
  chart_version = var.monitoring_version
  cluster_id    = each.value.id
  strict_taints = var.use_monitoring_taint
  # project_id    = each.value.project

  depends_on = [
    rancher2_project.this
  ]
}

module "bulk_components" {
  for_each = local.provision_components == true ? local.clusters_info : {}
  source   = "../../../bulk-components"
  providers = {
    rancher2 = rancher2
  }
  rancher_api_url   = var.rancher_api_url
  rancher_token_key = var.rancher_token_key
  output_local_file = false

  cluster_name         = each.value.name
  project              = each.value.project
  namespace            = "baseline-${each.value.id}-namespace-0"
  num_projects         = var.num_projects
  num_namespaces       = var.num_namespaces
  num_secrets          = var.num_secrets
  num_users            = var.num_users
  name_prefix          = "baseline-${each.value.id}"
  user_project_binding = true
  user_password        = var.user_password

  depends_on = [
    rancher2_cluster_sync.cluster_v1,
    rancher2_cluster_sync.cluster_v2,
    rancher2_project.this,
    module.rancher_monitoring
  ]
}
