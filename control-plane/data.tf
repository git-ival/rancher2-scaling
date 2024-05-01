data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

data "aws_route53_zone" "selected" {
  name         = "${local.domain}."
  private_zone = false
}

data "aws_secretsmanager_secret" "db_password_secret" {
  count = var.k8s_distribution == "k3s" ? 1 : 0
  arn   = module.db[0].db_instance_master_user_secret_arn
}

data "aws_secretsmanager_secret_version" "db_instance_password" {
  count     = var.k8s_distribution == "k3s" ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.db_password_secret[0].id
}
