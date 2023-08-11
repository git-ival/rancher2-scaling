output "metadata" {
  value = { for i, e in helm_release.local_chart[*].metadata : i => jsonencode(e) }
}

output "manifest" {
  value = { for i, e in helm_release.local_chart[*].manifest : i => e }
}

resource "local_file" "metadata" {
  for_each = { for i, e in helm_release.local_chart[*].metadata : i => jsonencode(e) }
  content  = each.value
  filename = "${path.module}/files/metadata/${terraform.workspace}metadata-${each.key}.json"
}

resource "local_file" "manifest" {
  for_each = { for i, e in helm_release.local_chart[*].manifest : i => e }
  content  = each.value
  filename = "${path.module}/files/manifests/${terraform.workspace}_manifest-${each.key}.json"
}
