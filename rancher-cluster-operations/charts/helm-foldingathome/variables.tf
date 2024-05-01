# variable "rancher_url" {
#   default     = null
#   type        = string
#   description = "The Rancher Server's URL"
# }

# variable "rancher_token" {
#   default     = null
#   type        = string
#   description = "Rancher2 API token for authentication"
# }

variable "values" {
  default     = null
  type        = string
  description = "Path to values template file for helm-foldingathome. Must enable setting hpa.maxReplicas via var.max_replicas"
}

variable "cluster_id" {
  default     = "local"
  type        = string
  description = "ID of the cluster to target"
}

variable "max_replicas" {
  default     = 15
  type        = number
  description = "The maximum # of folding pods allowed"
}

variable "timeouts" {
  default = null
  type = object({
    create = optional(string, "10m")
    update = optional(string, "10m")
    delete = optional(string, "10m")
  })
  description = "A map of string representing the timeouts for each resource operation: ['create', 'update', 'delete']."
}
