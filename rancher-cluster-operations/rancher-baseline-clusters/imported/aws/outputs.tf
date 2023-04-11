output "cluster_names" {
  value = local.cluster_names
}

output "public_ip" {
  value = aws_instance.this.public_ip
}

output "instance_id" {
  value = aws_instance.this.id
}
