data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_availability_zone" "selected_az" {
  zone_id = local.instance_az_zone_id
}

data "aws_security_group" "selected" {
  for_each = toset(var.security_groups)
  name     = each.key
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone-id"
    values = ["${data.aws_availability_zone.selected_az.zone_id}"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["${var.image}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "random_password" "k3s_cluster_secret" {
  length  = 30
  special = false
}

data "cloudinit_config" "k3s" {
  gzip          = false
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "00_cloud-config-base.yaml"
    content_type = "text/cloud-config"
    content = templatefile("../../../../control-plane/modules/aws-infra/files/cloud-config-base.tmpl", {
      ssh_keys = var.ssh_keys,
      }
    )
  }

  part {
    filename     = "02_k8s-setup.sh"
    content_type = "text/x-shellscript"
    content      = file("../../../../control-plane/modules/aws-infra/files/k8s-setup.sh")
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}
