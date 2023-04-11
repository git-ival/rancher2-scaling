# resource "rancher2_cluster_v2" "rke2" {
#   name               = "${local.cluster_name}-rke2"
#   kubernetes_version = var.rke2_version
#   dynamic "agent_env_vars" {
#     for_each = var.agent_env_vars == null ? [] : var.agent_env_vars
#     iterator = agent_var
#     content {
#       name  = agent_var.value.name
#       value = agent_var.value.value
#     }
#   }
#   timeouts {
#     create = "15m"
#   }
# }

# resource "rancher2_cluster_v2" "k3s" {
#   name               = "${local.cluster_name}-k3s"
#   kubernetes_version = var.k3s_version
#   dynamic "agent_env_vars" {
#     for_each = var.agent_env_vars == null ? [] : var.agent_env_vars
#     iterator = agent_var
#     content {
#       name  = agent_var.value.name
#       value = agent_var.value.value
#     }
#   }
#   timeouts {
#     create = "15m"
#   }
# }

resource "rancher2_cluster" "k3s" {
  name        = "${local.cluster_name}-k3s"
  description = "TF imported cluster ${local.cluster_name}-k3s"
}

### TODO: Add RKE1 and RKE2 support

# resource "rancher2_cluster_sync" "rke2" {
#   cluster_id    = rancher2_cluster_v2.rke2.cluster_v1_id
#   state_confirm = 3
# }

resource "rancher2_cluster_sync" "k3s" {
  # cluster_id    = rancher2_cluster_v2.k3s.cluster_v1_id
  cluster_id    = rancher2_cluster.k3s.id
  state_confirm = 3
  depends_on = [
    aws_instance.this
  ]
}

# resource "local_file" "rke2" {
#   content         = rancher2_cluster_sync.rke2.kube_config
#   filename        = "${path.module}/files/kube_config/${rancher2_cluster_v2.rke2.name}_kube_config"
#   file_permission = "0700"
# }

resource "local_file" "k3s" {
  content = rancher2_cluster_sync.k3s.kube_config
  # filename        = "${path.module}/files/kube_config/${rancher2_cluster_v2.k3s.name}_kube_config"
  filename        = "${path.module}/files/kube_config/${rancher2_cluster.k3s.name}_kube_config"
  file_permission = "0700"
}
