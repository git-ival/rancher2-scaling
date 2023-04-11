variable "num_users" {
  type        = number
  default     = 0
  description = "Number of new users to create, not to be used with var.users"
}

variable "user_password" {
  type        = string
  description = "Password to use for created users"
  sensitive   = true
}

variable "create_new_users" {
  type    = bool
  default = true
}

variable "users" {
  type = list(object({
    name     = string
    username = optional(string)
  }))
  default     = []
  description = "A list of maps with at least a 'name' or username' field, not to be used with var.num_users"
}

variable "user_name_ref_pattern" {
  type    = string
  default = ""
}

variable "user_global_binding" {
  type    = bool
  default = false
}

variable "user_global_rules" {
  type = list(object({
    api_groups        = optional(list(string))
    non_resource_urls = optional(list(string))
    resource_names    = optional(list(string))
    resources         = optional(list(string))
    verbs             = optional(list(string))
  }))
  default = [{
    api_groups = ["*"]
    resources  = ["secrets"]
    verbs      = ["create"]
  }]
  nullable = false
  validation {
    condition     = alltrue([for rule in var.user_global_rules[*] : rule.verbs != null ? length(rule.verbs) > 0 : true])
    error_message = "var.user_global_rules[#].verbs cannot be a list of length 0, please either omit the value or set to a valid list of strings."
  }
  validation {
    condition = alltrue([for rule in var.user_global_rules[*] : alltrue(
      [for verb in rule.verbs : contains(["bind", "create", "delete", "deletecollection", "escalate", "get", "impersonate",
      "list", "patch", "update", "use", "view", "watch", "own", "*"], verb)]
    )])
    error_message = "Each string in var.user_global_rules[#].verbs must match one of the values listed in the `rancher2_global_role` resource: https://registry.terraform.io/providers/rancher/rancher2/latest/docs/resources/global_role#verbs"
  }
}

variable "user_cluster_binding" {
  type    = bool
  default = false
}

variable "user_cluster_rules" {
  type = list(object({
    api_groups        = optional(list(string))
    non_resource_urls = optional(list(string))
    resource_names    = optional(list(string))
    resources         = optional(list(string))
    verbs             = optional(list(string))
  }))
  default = [{
    api_groups = ["*"]
    resources  = ["secrets"]
    verbs      = ["create"]
  }]
  nullable = false
  validation {
    condition     = alltrue([for rule in var.user_cluster_rules[*] : rule.verbs != null ? length(rule.verbs) > 0 : true])
    error_message = "var.user_cluster_rules[#].verbs cannot be a list of length 0, please either omit the value or set to a valid list of strings."
  }
  validation {
    condition = alltrue([for rule in var.user_cluster_rules[*] : alltrue(
      [for verb in rule.verbs : contains(["bind", "create", "delete", "deletecollection", "escalate", "get", "impersonate",
      "list", "patch", "update", "use", "view", "watch", "own", "*"], verb)]
    )])
    error_message = "Each string in var.user_cluster_rules[#].verbs must match one of the values listed in the `rancher2_role_template` resource: https://registry.terraform.io/providers/rancher/rancher2/latest/docs/resources/role_template#verbs"
  }
}

variable "user_project_binding" {
  type    = bool
  default = false
}

variable "user_project_roles" {
  type = list(object({
    api_groups        = optional(list(string))
    non_resource_urls = optional(list(string))
    resource_names    = optional(list(string))
    resources         = optional(list(string))
    verbs             = optional(list(string))
  }))
  default = [{
    api_groups = ["*"]
    resources  = ["secrets"]
    verbs      = ["create"]
  }]
  nullable = false
  validation {
    condition     = alltrue([for rule in var.user_project_roles[*] : rule.verbs != null ? length(rule.verbs) > 0 : true])
    error_message = "var.user_project_roles[#].verbs cannot be a list of length 0, please either omit the value or set to a valid list of strings."
  }
  validation {
    condition = alltrue([for rule in var.user_project_roles[*] : alltrue(
      [for verb in rule.verbs : contains(["bind", "create", "delete", "deletecollection", "escalate", "get", "impersonate",
      "list", "patch", "update", "use", "view", "watch", "own", "*"], verb)]
    )])
    error_message = "Each string in var.user_project_roles[#].verbs must match one of the values listed in the `rancher2_role_template` resource: https://registry.terraform.io/providers/rancher/rancher2/latest/docs/resources/role_template#verbs"
  }
}
