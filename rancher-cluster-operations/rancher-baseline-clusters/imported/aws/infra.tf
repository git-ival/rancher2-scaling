resource "aws_instance" "k3s" {
  count           = var.node_count
  ebs_optimized   = true
  instance_type   = var.server_instance_type
  ami             = data.aws_ami.ubuntu.id
  security_groups = var.security_groups
  user_data       = data.cloudinit_config.k3s.rendered

  tags = {
    Name           = "${local.cluster_name}-k3s-${count.index}"
    RancherScaling = local.cluster_name
    Owner          = data.aws_caller_identity.current.user_id
    DoNotDelete    = "true"
  }

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  depends_on = [rancher2_cluster.k3s]
}


resource "ssh_resource" "wait_for_bootstrap" {
  for_each = local.k3s_instances
  host     = each.value.public_ip
  user     = "ubuntu"
  agent    = true
  # An ssh-agent with your SSH private keys should be running
  # Use 'private_key' to set the SSH key otherwise

  # Try to complete in at most 5 minutes and wait 5 seconds between retries
  timeout     = "5m"
  retry_delay = "5s"

  commands = [
    "cloud-init status --wait"
  ]

  depends_on = [
    aws_instance.k3s
  ]
}

resource "ssh_resource" "init_leader" {
  host  = local.k3s_instances["0"].public_ip
  user  = "ubuntu"
  agent = true
  # An ssh-agent with your SSH private keys should be running
  # Use 'private_key' to set the SSH key otherwise

  # Try to complete in at most 5 minutes and wait 5 seconds between retries
  timeout     = "5m"
  retry_delay = "5s"

  file {
    content = templatefile("../../utils/k3s-install.sh", {
      sleep_at_startup    = false
      install_k3s_version = var.k3s_version,
      install_command     = local.leader_install,
      k3s_cluster_secret  = local.k3s_cluster_secret,
      is_k3s_server       = true,
      k3s_url             = local.k3s_instances["0"].public_ip
      k3s_disable_agent   = "",
      k3s_tls_san         = "",
      k3s_deploy_traefik  = "--disable=traefik"
      }
    )
    destination = "/tmp/k3s-install.sh"
    permissions = "0700"
  }

  commands = local.leader_commands

  depends_on = [
    ssh_resource.wait_for_bootstrap
  ]
}

resource "ssh_resource" "init_servers" {
  for_each = local.server_instances
  host     = each.value.public_ip
  user     = "ubuntu"
  agent    = true
  # An ssh-agent with your SSH private keys should be running
  # Use 'private_key' to set the SSH key otherwise

  # Try to complete in at most 5 minutes and wait 5 seconds between retries
  timeout     = "5m"
  retry_delay = "5s"

  file {
    content = templatefile("../../utils/k3s-install.sh", {
      sleep_at_startup    = true,
      install_k3s_version = var.k3s_version,
      install_command     = local.server_install,
      k3s_cluster_secret  = local.k3s_cluster_secret,
      is_k3s_server       = true,
      }
    )
    destination = "/tmp/k3s-install.sh"
    permissions = "0700"
  }

  commands = local.leader_commands

  depends_on = [
    ssh_resource.init_leader
  ]
}
