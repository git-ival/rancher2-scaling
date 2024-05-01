resource "aws_security_group" "registered_cluster" {
  count  = var.create_registered_cluster_security_group ? 1 : 0
  name   = "${local.name}-self"
  vpc_id = data.aws_vpc.default.id
  tags = {
    for tag in local.custom_tags : "${tag.key}" => "${tag.value}"
  }
}

# resource "aws_security_group_rule" "self_registered_self" {
#   count = var.create_registered_cluster_security_group ? 1 : 0
#   type              = "ingress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   self              = true
#   security_group_id = aws_security_group.registered_cluster[0].id
# }

resource "aws_security_group_rule" "registered_api" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "TCP"
  cidr_blocks       = local.private_subnets_cidr_blocks
  security_group_id = aws_security_group.registered_cluster[0].id
  description       = "K8s API"
}

resource "aws_security_group_rule" "self_registered_calico_bgp" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 179
  to_port           = 179
  protocol          = "TCP"
  self              = true
  security_group_id = aws_security_group.registered_cluster[0].id
  description       = "Calico BGP Port"
}

resource "aws_security_group_rule" "registered_dockerd_tls" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 2376
  to_port           = 2376
  protocol          = "TCP"
  cidr_blocks       = local.private_subnets_cidr_blocks
  security_group_id = aws_security_group.registered_cluster[0].id
  description       = "Node driver Docker daemon TLS port"
}

resource "aws_security_group_rule" "self_registered_etcd_comms" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 2379
  to_port           = 2380
  protocol          = "TCP"
  self              = true
  security_group_id = aws_security_group.registered_cluster[0].id
  description       = "etcd"
}

resource "aws_security_group_rule" "self_registered_vxlan" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 8472
  to_port           = 8472
  protocol          = "UDP"
  self              = true
  security_group_id = aws_security_group.registered_cluster[0].id
  description       = "Canal/Flannel VXLAN overlay networking"
}

resource "aws_security_group_rule" "self_registered_vxlan_liveness_readiness" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 9099
  to_port           = 9099
  protocol          = "TCP"
  self              = true
  security_group_id = aws_security_group.registered_cluster[0].id
  description       = "Canal/Flannel livenessProbe/readinessProbe"
}

resource "aws_security_group_rule" "self_registered_prom_metrics_linux" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 9100
  to_port           = 9100
  protocol          = "TCP"
  self              = true
  security_group_id = aws_security_group.registered_cluster[0].id
  description       = "Default port required by Monitoring to scrape metrics from Linux node-exporters"
}

resource "aws_security_group_rule" "self_registered_prom_metrics_windows" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 9796
  to_port           = 9796
  protocol          = "TCP"
  self              = true
  security_group_id = aws_security_group.registered_cluster[0].id
  description       = "Default port required by Monitoring to scrape metrics from Windows node-exporters"
}

resource "aws_security_group_rule" "self_registered_kubelet" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "TCP"
  self              = true
  security_group_id = aws_security_group.registered_cluster[0].id
  description       = "Metrics server communication with all nodes API"
}

resource "aws_security_group_rule" "self_registered_ingress_liveness_readiness" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 10254
  to_port           = 10254
  protocol          = "TCP"
  self              = true
  security_group_id = aws_security_group.registered_cluster[0].id
  description       = "Ingress controller livenessProbe/readinessProbe"
}

resource "aws_security_group_rule" "registered_nodeport_range" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.registered_cluster[0].id
  description       = "Workload Nodeports"
}

resource "aws_security_group_rule" "registered_server_egress" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.registered_cluster[0].id
  description       = "Egress all traffic"
}

resource "aws_security_group_rule" "registered_ssh_server" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.registered_cluster[0].id
  description       = "SSH"
}

resource "aws_security_group_rule" "registered_8443" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.registered_cluster[0].id
}

resource "aws_security_group_rule" "registered_9443" {
  count             = var.create_registered_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 9443
  to_port           = 9443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.registered_cluster[0].id
}
