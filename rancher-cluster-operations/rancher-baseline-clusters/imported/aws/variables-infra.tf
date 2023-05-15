variable "ssh_keys" {
  type        = list(any)
  default     = []
  description = "SSH keys to inject into the EC2 instances"
}

variable "security_groups" {
  type        = list(any)
  default     = []
  description = "A list of security group names (EC2-Classic) or IDs (default VPC) to associate with"
}

variable "node_count" {
  type        = number
  default     = 3
  description = "The number of nodes to create for the cluster"
}

variable "server_instance_type" {
  type        = string
  description = "Cloud provider-specific instance type string to use for rke1 server"
}

variable "volume_size" {
  type        = string
  default     = "32"
  description = "Size of the storage volume to use in GB"
}

variable "volume_type" {
  type        = string
  default     = "gp2"
  description = "Type of storage volume to use"
}

variable "image" {
  type        = string
  default     = "ubuntu-minimal/images/*/ubuntu-bionic-18.04-*"
  description = "Specific AWS AMI or AMI name filter to use"
}

variable "iam_instance_profile" {
  type    = string
  default = null
}

variable "install_docker_version" {
  type        = string
  default     = "20.10"
  description = "The version of docker to install. Available docker versions can be found at: https://github.com/rancher/install-docker"
}

variable "k3s_cluster_secret" {
  type        = string
  default     = ""
  description = "k3s cluster secret"
}

variable "k3s_datastore_cafile" {
  default     = "/srv/rds-combined-ca-bundle.pem"
  type        = string
  description = "Location to download RDS CA Bundle"
}
