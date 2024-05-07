resource "rancher2_machine_config_v2" "this" {
  for_each      = local.v2_configs
  generate_name = "${each.value.name}${each.key}-nt"
  linode_config {
    image            = var.image
    instance_type    = var.server_instance_type
    region           = var.region
    authorized_users = var.authorized_users
    tags             = "RancherScaling:${local.rancher_subdomain},Owner:${local.rancher_subdomain}"
  }
}

resource "rancher2_cluster_v2" "cluster_v2" {
  for_each                                                   = local.v2_configs
  name                                                       = each.value.name
  kubernetes_version                                         = each.value.k8s_version
  cloud_credential_secret_name                               = module.cloud_credential.id
  default_pod_security_admission_configuration_template_name = each.value.psa_config
  local_auth_endpoint {
    enabled = true
  }
  dynamic "fleet_agent_deployment_customization" {
    for_each = local.v2_fleet_customization
    iterator = customization
    content {
      dynamic "append_tolerations" {
        for_each = contains(keys(customization.value), "append_tolerations") ? customization.value.append_tolerations : []
        iterator = toleration
        content {
          key      = try(toleration.value.key, "")
          operator = try(toleration.value.operator, "")
          value    = try(toleration.value.value, "")
          effect   = try(toleration.value.effect, "")
          seconds  = try(toleration.value.seconds, null)
        }
      }
      override_affinity = contains(keys(customization.value), "override_affinity") ? customization.value.override_affinity : ""
      dynamic "override_resource_requirements" {
        for_each = contains(keys(customization.value), "override_resource_requirements") ? customization.value.override_resource_requirements : []
        iterator = requirement
        content {
          cpu_limit      = try(requirement.value.cpu_limit, "")
          cpu_request    = try(requirement.value.cpu_request, "")
          memory_limit   = try(requirement.value.memory_limit, "")
          memory_request = try(requirement.value.memory_request, "")
        }
      }
    }
  }
  dynamic "agent_env_vars" {
    for_each = var.agent_env_vars == null ? [] : var.agent_env_vars
    iterator = agent_var
    content {
      name  = agent_var.value.name
      value = agent_var.value.value
    }
  }
  rke_config {
    dynamic "machine_pools" {
      for_each = each.value.roles_per_pool
      iterator = pool
      content {
        name                         = "${each.value.name}-${pool.key}"
        cloud_credential_secret_name = module.cloud_credential.id
        control_plane_role           = try(tobool(pool.value.control-plane), false)
        worker_role                  = try(tobool(pool.value.worker), false)
        etcd_role                    = try(tobool(pool.value.etcd), false)
        quantity                     = try(tonumber(pool.value.quantity), 1)
        machine_labels               = try(pool.value.labels, null)
        dynamic "taints" {
          for_each = pool.value.taints
          iterator = taint
          content {
            key    = try(taint.value.key, "")
            value  = try(taint.value.value, "")
            effect = try(taint.value.effect, "")
          }
        }

        machine_config {
          kind = rancher2_machine_config_v2.this[each.key].kind
          name = rancher2_machine_config_v2.this[each.key].name
        }
      }
    }
  }
  timeouts {
    create = "15m"
  }
  depends_on = [
    module.cloud_credential,
    rancher2_pod_security_admission_configuration_template.rancher_restricted_folding
  ]
}

resource "rancher2_cluster_sync" "cluster_v2" {
  count         = local.v2_count
  cluster_id    = local.v2_clusters[count.index].cluster_v1_id
  state_confirm = 3
}

resource "local_file" "v2_kube_config" {
  count           = length(local.v2_kube_config_list)
  content         = local.v2_kube_config_list[count.index]
  filename        = "${path.module}/files/kube_config/${terraform.workspace}_${local.v2_clusters[count.index].name}_kube_config"
  file_permission = "0700"
}
