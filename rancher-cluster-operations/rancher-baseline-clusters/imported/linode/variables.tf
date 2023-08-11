variable "name_suffix" {
  type        = string
  default     = ""
  description = "(Optional) suffix to append to your cloud credential, node template and node pool names"
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
