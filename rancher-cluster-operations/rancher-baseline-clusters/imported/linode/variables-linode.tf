# variable "linode_config_path" {
#   type        = string
#   default     = "~/.config/linode"
#   description = "The path to the Linode config file to use (https://registry.terraform.io/providers/linode/linode/latest/docs#using-configuration-files)"
# }

# variable "linode_config_profile" {
#   type        = string
#   default     = "default"
#   description = "The Linode config profile to use (https://registry.terraform.io/providers/linode/linode/latest/docs#using-configuration-files)"
# }

variable "linode_token" {
  type        = string
  description = "Linode API token"
  nullable    = false
  sensitive   = true
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
  default     = "ubuntu/20.04"
  description = <<-EOT
  The image ID to use for the selected cloud provider.
  AWS assumes an AMI ID, Linode assumes a linode image.
  Defaults to the latest 20.04 Ubuntu image.
  EOT
}

variable "linode_group" {
  type        = string
  default     = ""
  description = "The display group for the linode(s). Defaults to the generated cluster_name if not set"
}

variable "linode_keys" {
  type        = list(string)
  default     = null
  description = "A list of SSH public keys to deploy for the root user on the newly created Linode"
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

variable "root_pass" {
  type        = string
  description = "(Optional) The root user’s password on a newly-created Linode."
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

variable "tags" {
  type        = list(string)
  default     = []
  description = "A comma-separated list of tags"
}
