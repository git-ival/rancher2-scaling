variable "name_suffix" {
  type        = string
  default     = ""
  description = "(Optional) suffix to append to your cloud credential, node template and node pool names"
}

variable "region" {
  type        = string
  default     = "us-west-1"
  description = "AWS-specific region string. Defaults to an AWS-specific region"
}

variable "aws_access_key" {
  type      = string
  default   = null
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  default   = null
  sensitive = true
}

variable "rancher_api_url" {
  type        = string
  description = "api url for rancher server"
}

variable "rancher_token_key" {
  type        = string
  description = "rancher server API token"
}

variable "insecure_flag" {
  type        = bool
  default     = false
  description = "Flag used to determine if Rancher is using self-signed invalid certs (using a private CA)"
}
