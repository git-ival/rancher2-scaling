variable "install_certmanager" {
  default     = true
  type        = bool
  description = "Boolean that defines whether or not to install Cert-Manager"
}

variable "certmanager_version" {
  type        = string
  default     = "1.10.2"
  description = "Version of cert-manager to install"
}

variable "byo_certs_bucket_path" {
  default     = ""
  type        = string
  description = "Optional: String that defines the path on the S3 Bucket where your certs are stored. NOTE: assumes certs are stored in a tarball within a folder below the top-level bucket e.g.: my-bucket/certificates/my_certs.tar.gz. Certs should be stored within a single folder, certs nested in sub-folders will not be handled"
}

variable "s3_instance_profile" {
  default     = ""
  type        = string
  description = "Optional: String that defines the name of the IAM Instance Profile that grants S3 access to the EC2 instances. Required if 'byo_certs_bucket_path' is set"
}

variable "s3_bucket_region" {
  default     = ""
  type        = string
  description = "Optional: String that defines the AWS region of the S3 Bucket that stores the desired certs. Required if 'byo_certs_bucket_path' is set. Defaults to the aws_region if not set"
}

variable "private_ca_file" {
  default     = ""
  type        = string
  description = "Optional: String that defines the name of the private CA .pem file in the specified S3 bucket's cert tarball"
}

variable "tls_cert_file" {
  default     = ""
  type        = string
  description = "Optional: String that defines the name of the TLS Certificate file in the specified S3 bucket's cert tarball. Required if 'byo_certs_bucket_path' is set"
}

variable "tls_key_file" {
  default     = ""
  type        = string
  description = "Optional: String that defines the name of the TLS Key file in the specified S3 bucket's cert tarball. Required if 'byo_certs_bucket_path' is set"
}

variable "ssh_keys" {
  type        = list(any)
  default     = []
  description = "SSH keys to inject into Rancher instances"
}

variable "ssh_key_path" {
  default     = null
  type        = string
  description = "Path to the private SSH key file to be used for connecting to the node(s)"
}

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
  default     = "us-west-1"
  description = "The cloud provider-specific region string"
}

variable "user" {
  type        = string
  default     = "ubuntu"
  description = "Name of the user to SSH as"
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

