resource "random_id" "index" {
  byte_length = 2
}

locals {
  ### AWS Data
  az_zone_ids_list         = tolist(data.aws_availability_zones.available.zone_ids)
  az_zone_ids_random_index = random_id.index.dec % length(local.az_zone_ids_list)
  instance_az_zone_id      = local.az_zone_ids_list[local.az_zone_ids_random_index]
  selected_az_suffix       = data.aws_availability_zone.selected_az.name_suffix
  subnet_ids_list          = tolist(data.aws_subnets.available.ids)
  subnet_ids_random_index  = random_id.index.dec % length(local.subnet_ids_list)
  instance_subnet_id       = local.subnet_ids_list[local.subnet_ids_random_index]
  security_groups          = [for group in data.aws_security_group.selected : group.name]
  ### Naming
  name_max_length   = 60
  rancher_subdomain = split(".", split("//", "${var.rancher_api_url}")[1])[0]
  name_suffix       = length(var.name_suffix) > 0 ? var.name_suffix : "${terraform.workspace}"
  cluster_name      = length(var.cluster_name) > 0 ? var.cluster_name : "${substr("${local.rancher_subdomain}-${local.name_suffix}", 0, local.name_max_length)}"
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
  k3s_instances = { for i, node in aws_instance.k3s[*] :
    i => {
      ami        = node.ami
      arn        = node.arn
      private_ip = node.private_ip
      public_ip  = node.public_ip
    }
  }
  leader_instance = local.k3s_instances["0"]
  server_instances = {
    1 = local.k3s_instances["1"]
    2 = local.k3s_instances["2"]
  }
  k3s_cluster_secret = length(var.k3s_cluster_secret) > 0 ? var.k3s_cluster_secret : random_password.k3s_cluster_secret.result
  leader_commands = [
    "sudo /tmp/k3s-install.sh",
    "${rancher2_cluster.k3s.cluster_registration_token[0].command}"
  ]
  server_commands = ["sudo /tmp/k3s-install.sh"]
  leader_install  = "curl -sfL https://get.k3s.io | K3S_TOKEN=${local.k3s_cluster_secret} sh -s - server --cluster-init --write-kubeconfig-mode=0644"
  server_install  = "curl -sfL https://get.k3s.io | K3S_TOKEN=${local.k3s_cluster_secret} sh -s - server --server https:${local.k3s_instances["0"].public_ip}:6443 --write-kubeconfig-mode=0644"

  k3s_kube_config = rancher2_cluster_sync.k3s.kube_config
  clusters        = [rancher2_cluster.k3s]
  cluster_names   = [rancher2_cluster.k3s.name]
  clusters_info = {
    for i, cluster in local.clusters :
    i => {
      id      = try(cluster.cluster_v1_id, cluster.id)
      name    = cluster.name
      project = "baseline-components"
    }
  }
}

resource "rancher2_project" "this" {
  for_each   = local.clusters_info
  cluster_id = each.value.id
  name       = each.value.project
  depends_on = [
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
    rancher2_cluster_sync.k3s,
    rancher2_project.this
  ]
}
