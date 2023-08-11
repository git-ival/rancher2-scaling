locals {
  release_prefix = length(var.release_prefix) > 0 ? var.release_prefix : terraform.workspace
}

resource "helm_release" "local_chart" {
  count            = length(var.local_chart_path) > 0 ? var.num_charts : 0
  name             = "${var.release_prefix}-${count.index}"
  chart            = var.local_chart_path
  namespace        = var.namespace
  create_namespace = true
  wait             = true
  wait_for_jobs    = true
  values = [
    "${file(var.values)}"
  ]
}
