variable "infra_provider" {
  type        = string
  description = "(optional) describe your variable"
  nullable    = false
  validation {
    condition     = contains(["aws", "linode"], var.infra_provider)
    error_message = "The infrastructure provider to use, must be one of ['aws', 'linode']."
  }
}

variable "region" {
  type        = string
  default     = "us-west"
  description = "The cloud provider-specific region string"
}

variable "node_type" {
  type        = string
  default     = null
  description = "Cloud provider-specific node/instance type used for the rancher servers"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "node_image" {
  type        = string
  default     = null
  description = <<-EOT
  The image ID to use for the selected cloud provider.
  AWS assumes an AMI ID, Linode assumes a linode image.
  Defaults to the latest 18.04 Ubuntu image.
  EOT
}

variable "linode_users" {
  type        = list(string)
  default     = null
  description = <<-EOT
  List of Linode usernames that are authorized to access the linode(s).
  If the usernames have associated SSH keys, the keys will be appended to the root user's ~/.ssh/authorized_keys file automatically.
  Changing this list forces the creation of new Linode(s).
  EOT
}

variable "linode_token" {
  type        = string
  description = "Linode API token"
  nullable    = false
  sensitive   = true
}

variable "random_prefix" {
  type        = string
  default     = "rancher"
  description = "Prefix to be used with random name generation"
}

variable "letsencrypt_email" {
  type        = string
  default     = "none@none.com"
  description = "LetsEncrypt email address to use"
}

variable "domain" {
  type    = string
  default = ""
}

variable "r53_domain" {
  type        = string
  default     = ""
  description = "DNS domain for Route53 zone (defaults to domain if unset)"
}

