variable "name_suffix" {
  type        = string
  default     = ""
  description = "(Optional) suffix to append to your cloud credential, node template and node pool names. This must be unique per-workspace in order to not conflict with any resources"
}

variable "cluster_name" {
  type        = string
  default     = ""
  description = "(Optional) Desired cluster name, if not set then one will be generated"
}

variable "cluster_labels" {
  type        = map(any)
  default     = {}
  description = "(Optional) Labels to add to each provisioned cluster"
}

# variable "roles_per_pool" {
#   type = list(map(string))
#   default = [
#     {
#       "quantity"      = 3
#       "etcd"          = true
#       "control-plane" = true
#       "worker"        = true
#     }
#   ]
#   description = <<EOF
#   A list of maps where each element contains keys that define the roles and quantity for a given node pool.
#   Example: [
#     {
#       "quantity" = 3
#       "etd" = true
#       "control-plane" = true
#       "worker" = true
#     }
#   ]
#   EOF
#   validation {
#     condition     = contains([1, 3, 5], sum([for i, pool in var.roles_per_pool : try(tonumber(pool["quantity"]), 1) if try(pool["etcd"] == "true", false)]))
#     error_message = "The number of etcd nodes per cluster must be one of [1, 3, 5]."
#   }
#   validation {
#     condition     = sum([for i, pool in var.roles_per_pool : try(tonumber(pool["quantity"]), 1) if try(pool["control-plane"] == "true", false)]) >= 1
#     error_message = "The number of control-plane nodes per cluster must be >= 1."
#   }
#   validation {
#     condition     = sum([for i, pool in var.roles_per_pool : try(tonumber(pool["quantity"]), 1) if try(pool["worker"] == "true", false)]) >= 1
#     error_message = "The number of worker nodes per cluster must be >= 1."
#   }
# }

variable "cloud_cred_name" {
  type        = string
  default     = ""
  description = "(Optional) Name to use for the cloud credential."
}

variable "node_template_name" {
  type        = string
  default     = ""
  description = "(Optional) Name to use for the node template."
}

variable "create_node_reqs" {
  type        = bool
  default     = true
  description = "Flag defining if a cloud credential & node template should be created on tf apply. Useful for scripting purposes"
}

variable "region" {
  type        = string
  default     = "us-west-1"
  description = "Cloud provider-specific region string. Defaults to an AWS-specific region"
}

variable "linode_token" {
  type      = string
  default   = null
  sensitive = true
}

variable "authorized_users" {
  type        = string
  default     = null
  description = "(Optional) Linode user accounts (seperated by commas) whose Linode SSH keys will be permitted root access to the created node."
}

variable "image" {
  type        = string
  default     = "linode/ubuntu18.04"
  description = "Linode-specific image name string"
}

variable "install_docker_version" {
  type        = string
  default     = "20.10"
  description = "The version of docker to install. Available docker versions can be found at: https://github.com/rancher/install-docker"
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

variable "cluster_configs" {
  type = list(object({
    k8s_version      = string
    k8s_distribution = string
  }))
  description = "A list of objects with key-value pairs for the k8s version and distribution to be used for the clusters."
  validation {
    condition     = length(var.cluster_configs) == 3
    error_message = "var.cluster_configs must be a list of 3 objects."
  }
  validation {
    condition     = alltrue([for i, config in var.cluster_configs : contains(["rke1", "rke2", "k3s"], config.k8s_distribution)])
    error_message = "var.cluster_configs[*].k8s_distribution must be a list of 3 strings, with each string matching one of [\"rke1\", \"rke2\", \"k3s\"]."
  }
  validation {
    condition     = length([for i, config in var.cluster_configs : config.k8s_version]) == 3
    error_message = "var.cluster_configs[*].k8s_version must be a list of 3 strings matching valid k8s versions with respect to the k8s_distribution of this object."
  }
  validation {
    condition     = length([for i, config in var.cluster_configs : can(regex("v", config.k8s_version))]) == 3
    error_message = "Each version number must be prefixed with 'v'."
  }
}

variable "kube_api_debugging" {
  type        = bool
  default     = false
  description = "A flag defining if more verbose logging should be enabled for the kube_api service"
}

variable "agent_env_vars" {
  type        = list(map(string))
  default     = null
  description = "A list of maps representing Rancher agent environment variables: https://registry.terraform.io/providers/rancher/rancher2/latest/docs/resources/cluster#agent_env_vars"
  validation {
    condition     = var.agent_env_vars == null ? true : length(var.agent_env_vars) == 0 ? true : sum([for var in var.agent_env_vars : 1 if lookup(var, "name", "false") != "false"]) == length(var.agent_env_vars)
    error_message = "Each env var map must contain key-value pairs for the \"name\" and \"value\" keys."
  }
  validation {
    condition     = var.agent_env_vars == null ? true : length(var.agent_env_vars) == 0 ? true : sum([for var in var.agent_env_vars : 1 if lookup(var, "value", "false") != "false"]) == length(var.agent_env_vars)
    error_message = "Each env var map must contain key-value pairs for the \"name\" and \"value\" keys."
  }
}

variable "enable_cri_dockerd" {
  type        = bool
  default     = false
  description = "(Optional) Enable/disable using cri-dockerd"
}

variable "node_template_engine_fields" {
  type = object({
    engine_env               = optional(map(string), null)
    engine_insecure_registry = optional(list(string), null)
    engine_install_url       = optional(string, null)
    engine_label             = optional(map(string), null)
    engine_opt               = optional(map(string), null)
    engine_registry_mirror   = optional(list(string), null)
    engine_storage_driver    = optional(string, null)
  })
  default     = null
  description = "A map of one-to-one keys with the various engine settings available on the `rancher2_node_template` resource: https://registry.terraform.io/providers/rancher/rancher2/latest/docs/resources/node_template#engine_storage_driver"
}

variable "auto_replace_timeout" {
  type        = number
  default     = null
  description = "Time to wait after Cluster becomes Active before deleting nodes that are unreachable"
}
