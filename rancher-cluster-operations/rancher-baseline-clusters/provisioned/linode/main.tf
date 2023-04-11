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
  rke1_kube_config = rancher2_cluster_sync.rke1.kube_config
  rke2_kube_config = rancher2_cluster_sync.rke2.kube_config
  k3s_kube_config  = rancher2_cluster_sync.k3s.kube_config
  clusters         = [module.rke1, rancher2_cluster_v2.rke2, rancher2_cluster_v2.k3s]
  cluster_names    = [module.rke1.name, rancher2_cluster_v2.rke2.name, rancher2_cluster_v2.k3s.name]
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
    rancher2_cluster_sync.rke1,
    rancher2_cluster_sync.rke2,
    rancher2_cluster_sync.k3s
  ]
}

module "bulk_components" {
  for_each = local.clusters_info
  source   = "../../../bulk-components"
  providers = {
    rancher2 = rancher2
  }
  rancher_api_url   = var.rancher_api_url
  rancher_token_key = var.rancher_token_key
  output_local_file = false

  cluster_name         = each.value.name
  project              = each.value.project
  num_projects         = var.num_projects
  num_namespaces       = var.num_namespaces
  num_secrets          = var.num_secrets
  num_users            = var.num_users
  name_prefix          = "baseline-${each.value.id}"
  user_project_binding = true
  user_password        = var.user_password

  depends_on = [
    rancher2_cluster_sync.rke1,
    rancher2_cluster_sync.rke2,
    rancher2_cluster_sync.k3s,
    rancher2_project.this
  ]
}
