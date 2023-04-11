locals {
  name_max_length   = 32
  firewall_name     = var.label != null ? substr(var.label, 0, local.name_max_length) : substr("${local.name}-rancher-firewall", 0, local.name_max_length)
  rancher_subdomain = split(".", split("//", "${var.rancher_api_url}")[1])[0]
  name_suffix       = length(var.name_suffix) > 0 ? var.name_suffix : "${terraform.workspace}"
  cluster_name      = length(var.cluster_name) > 0 ? var.cluster_name : "${substr("${local.rancher_subdomain}-${local.name_suffix}", 0, local.name_max_length)}"
  group             = try(length(var.group) > 0 ? var.group : local.name)
  nodebalancer_name = try(var.label != null, false) ? substr(var.label, 0, local.name_max_length) : substr(local.name, 0, local.name_max_length)
  rancher_inbound_rules = [
    {
      label    = "allow-https"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "443"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    }
  ]
  cluster_inbound_rules = [
    {
      label    = "docker-daemon-tls"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "2376"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "k8s-api-server"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "6443"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "rancher-catalog"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "443"
      ipv4     = ["35.160.43.145/32", "35.167.242.46/32", "52.33.59.17/32"]
      ipv6     = ["::/0"]
    },
    {
      label    = "calico-bgp"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "179"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "canal-flannel-VXLAN"
      action   = "ACCEPT"
      protocol = "UDP"
      ports    = "8472"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "canal-flannel-probe"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "9099"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "linux-metrics-exporter"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "9100"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "windows-metrics-exporter"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "9796"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "windows-flannel-VXLAN"
      action   = "ACCEPT"
      protocol = "UDP"
      ports    = "4789"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "ingress-probe"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "10254"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "metrics-server-api"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "10250"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "NodePort-range-tcp"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "30000-32767"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "NodePort-range-udp"
      action   = "ACCEPT"
      protocol = "UDP"
      ports    = "30000-32767"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "rancher-webhook1"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "8443"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "rancher-webhook2"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "9443"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "weave-tcp"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "6783"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "weave-udp"
      action   = "ACCEPT"
      protocol = "UDP"
      ports    = "6783-6784"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    },
    {
      label    = "etcd-client-peer-comms"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "2379-2380"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = ["::/0"]
    }
  ]
  final_rules = concat(local.rancher_inbound_rules, local.cluster_inbound_rules)
}

resource "linode_instance" "this" {
  count = var.node_count

  label            = try(var.label != null, false) ? substr(var.label, 0, local.name_max_length) : substr("${local.name}-${count.index}", 0, local.name_max_length)
  image            = var.image
  region           = var.region
  type             = var.instance_type
  authorized_keys  = var.authorized_keys
  authorized_users = var.authorized_users
  root_pass        = var.root_pass

  group       = local.group
  tags        = concat(var.tags, [local.name])
  swap_size   = var.swap_size
  private_ip  = var.private_ip
  shared_ipv4 = var.shared_ipv4

  ### disable alerts
  alerts {
    cpu            = 0
    network_in     = 0
    network_out    = 0
    transfer_quota = 0
    io             = 0
  }
  backups_enabled  = false
  watchdog_enabled = false
}

module "rancher_firewall" {
  source = "./firewall"
  providers = {
    linode = linode
  }

  label           = local.firewall_name
  inbound_rules   = local.final_rules
  inbound_policy  = "DROP"
  outbound_rules  = []
  outbound_policy = "ACCEPT"
  linodes         = linode_instance.this[*].id
  tags            = concat(var.tags, [local.name])
}
