output "cluster_names" {
  value = local.cluster_names
}

output "public_ips" {
  value = aws_instance.k3s[*].public_ip
}

output "instance_ids" {
  value = aws_instance.k3s[*].id
}
