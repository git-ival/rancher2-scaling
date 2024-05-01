variable "rke_metadata_url" {
  type    = string
  default = ""

}

variable "enable_secrets_encryption" {
  type        = bool
  default     = false
  description = "(Optional) Boolean that determines if secrets-encryption should be enabled on the underlying RKE nodes"
}

variable "enable_audit_log" {
  type        = bool
  default     = false
  description = "(Optional) Boolean that determines if audit logging should be enabled"
}

variable "enable_cri_dockerd" {
  type        = bool
  default     = true
  description = "(Optional) Boolean that determines if CRI dockerd is enabled for the kubelet (required for k8s >= v1.24.x)"
}

variable "system_images" {
  type        = map(any)
  default     = {}
  description = "A map specifying override values matching the keys at https://github.com/rancher/kontainer-driver-metadata"
}

variable "local_cluster_auth_endpoint" {
  type = object({
    enabled  = bool
    fqdn     = string
    ca_certs = string
  })
  default = {
    enabled  = true
    fqdn     = null
    ca_certs = null
  }
  description = "Enabling the local cluster authorized endpoint allows direct communication with the cluster, bypassing the Rancher API proxy"
}

variable "psa_config" {
  type        = string
  default     = ""
  description = "A string specifying which default RKE1 Pod Security Admission Configuration Template (PSACT) to use"
  validation {
    condition     = length(var.psa_config) == 0 ? true : contains(["privileged", "restricted"], var.psa_config)
    error_message = "var.psa_config must be one of ['privileged', 'restricted']."
  }
}

variable "psa_file" {
  type        = string
  default     = ""
  nullable    = false
  description = "The absolute path to a file containing a valid PSACT configuration to use"
  validation {
    condition     = length(var.psa_file) == 0 ? true : fileexists(var.psa_file)
    error_message = "Could not find var.psa_file (${var.psa_file}) in filesystem."
  }
}
