output "cluster_names" {
  value = [rancher2_cluster.k3s.name]
}

output "public_ip" {
  value = linode_instance.this[0].ip_address
}

output "instance_id" {
  value = linode_instance.this[0].id
}
