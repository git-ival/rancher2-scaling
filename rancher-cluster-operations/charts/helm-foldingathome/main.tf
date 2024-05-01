locals {
  default_values = abspath("${path.module}/files/values.yaml")
  values         = try(length(var.values) > 0 ? var.values : local.default_values, local.default_values)
  repo_name      = "helm-foldingathome"
  name           = "folding"
  chart_name     = "foldingathome-hpa"
  # cluster_v1_ids = [for cluster in data.rancher2_cluster.this : cluster.id]
  # cluster_v2_ids = [for cluster in data.rancher2_cluster_v2.this : cluster.id]
  # cluster_ids    = compact(concat(local.cluster_v1_ids, local.cluster_v2_ids))
  # cluster_ids = [for cluster in data.rancher2_cluster.this : cluster.id]
}

# data "rancher2_cluster" "this" {
#   for_each = toset(var.cluster_names)
#   name     = each.key
# }

# data "rancher2_cluster_v2" "this" {
#   for_each = toset(var.cluster_names)
#   name     = each.key
# }

resource "rancher2_project" "folding" {
  # for_each   = toset(var.cluster_ids)
  name = local.name
  # cluster_id = each.key
  cluster_id = var.cluster_id
}

resource "rancher2_catalog_v2" "helm-foldingathome" {
  # for_each   = toset(var.cluster_ids)
  cluster_id = var.cluster_id
  name       = local.repo_name
  git_repo   = "https://github.com/git-ival/helm-foldingathome"
  git_branch = "update-chart-image"

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }

  provisioner "local-exec" {
    command = <<-EOT
    sleep 10
    EOT
  }
}

data "rancher2_project" "folding" {
  # for_each   = toset(var.cluster_ids)
  cluster_id = var.cluster_id
  name       = local.name
  depends_on = [rancher2_project.folding]
}

resource "rancher2_app_v2" "helm-foldingathome" {
  # for_each   = data.rancher2_project.folding
  cluster_id = var.cluster_id
  project_id = data.rancher2_project.folding.id
  name       = local.name
  namespace  = local.name
  repo_name  = local.repo_name
  chart_name = local.chart_name
  values = templatefile(local.values, {
    max_replicas = var.max_replicas
  })

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }

  depends_on = [
    rancher2_catalog_v2.helm-foldingathome
  ]
}
