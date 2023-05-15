resource "rancher2_cluster" "k3s" {
  name        = "${local.cluster_name}-k3s"
  description = "TF imported cluster ${local.cluster_name}-k3s"
  dynamic "agent_env_vars" {
    for_each = var.agent_env_vars == null ? [] : var.agent_env_vars
    iterator = agent_var
    content {
      name  = agent_var.value.name
      value = agent_var.value.value
    }
  }
  timeouts {
    create = "15m"
  }
}

resource "rancher2_cluster_sync" "k3s" {
  cluster_id    = rancher2_cluster.k3s.id
  state_confirm = 3
  depends_on = [
    ssh_resource.init_servers
  ]
}

resource "local_file" "k3s" {
  content         = rancher2_cluster_sync.k3s.kube_config
  filename        = "${path.module}/files/kube_config/${rancher2_cluster.k3s.name}_kube_config"
  file_permission = "0700"
}
