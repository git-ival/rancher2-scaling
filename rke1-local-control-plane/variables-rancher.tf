variable "install_docker_version" {
  type        = string
  default     = "20.10"
  description = "Version of Docker to install"
}

variable "install_k8s_version" {
  type        = string
  default     = ""
  description = "Version of K8s to install"
}

variable "install_rancher" {
  type        = bool
  default     = true
  description = "Boolean that defines whether or not to install Rancher"
}

variable "rancher_version" {
  type        = string
  description = "Version of Rancher to install - Do not include the v prefix."
}

variable "rancher_loglevel" {
  type        = string
  description = "A string specifying the loglevel to set on the rancher pods. One of: info, debug or trace. https://rancher.com/docs/rancher/v2.x/en/troubleshooting/logging/"
  default     = "info"
}

variable "rancher_image" {
  type    = string
  default = "rancher/rancher"
}

variable "rancher_image_tag" {
  type        = string
  default     = "master-head"
  description = "Rancher image tag to install, this can differ from rancher_version which is the chart being used to install Rancher"
}

variable "rancher_password" {
  type        = string
  default     = ""
  description = "Password to set for admin user during bootstrap of Rancher Server, if not set random password will be generated"
}

variable "helm_rancher_repo" {
  default     = "https://releases.rancher.com/server-charts/latest"
  type        = string
  description = "The repo URL to use for Rancher Server charts"
}

variable "rancher_charts_repo" {
  type        = string
  default     = "https://git.rancher.io/charts"
  description = "The URL for the desired Rancher charts"
}

variable "rancher_charts_branch" {
  type        = string
  default     = "release-v2.6"
  description = "The github branch for the desired Rancher chart version"
}

variable "cattle_prometheus_metrics" {
  default     = true
  type        = bool
  description = "Boolean variable that defines whether or not to enable the CATTLE_PROMETHEUS_METRICS env var for Rancher"
}

variable "install_monitoring" {
  type        = bool
  default     = true
  description = "Boolean that defines whether or not to install rancher-monitoring"
}

variable "monitoring_version" {
  type        = string
  default     = ""
  description = "Version of Monitoring v2 to install - Do not include the v prefix."
}

variable "monitoring_crd_chart_values_path" {
  type        = string
  default     = null
  description = "Path to custom values.yaml for rancher-monitoring"
}

variable "monitoring_chart_values_path" {
  type        = string
  default     = null
  description = "Path to custom values.yaml for rancher-monitoring"
}

variable "sensitive_token" {
  type        = bool
  default     = true
  description = "Boolean that determines if the module should treat the generated Rancher Admin API Token as sensitive in the output."
}

variable "rancher_settings" {
  type = list(object({
    name        = string
    value       = any
    annotations = optional(map(string))
    labels      = optional(map(string))
  }))
  default     = []
  description = "A list of objects defining modifications to the named rancher settings"
}

variable "rancher_env_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  default     = []
  description = "A list of objects representing Rancher environment variables"
  validation {
    condition     = length(var.rancher_env_vars) == 0 ? true : sum([for var in var.rancher_env_vars : 1 if length(lookup(var, "name", "")) > 0]) == length(var.rancher_env_vars)
    error_message = "Each env var object must contain key-value pairs for the \"name\" and \"value\" keys."
  }
  validation {
    condition     = length(var.rancher_env_vars) == 0 ? true : sum([for var in var.rancher_env_vars : 1 if length(lookup(var, "value", "")) > 0]) == length(var.rancher_env_vars)
    error_message = "Each env var object must contain key-value pairs for the \"name\" and \"value\" keys."
  }
}

variable "rancher_additional_values" {
  type = list(object({
    name  = string
    value = string
  }))
  default     = []
  description = "A list of objects representing values for the Rancher helm chart"
  validation {
    condition     = length(var.rancher_additional_values) == 0 ? true : sum([for var in var.rancher_additional_values : 1 if length(lookup(var, "name", "")) > 0]) == length(var.rancher_additional_values)
    error_message = "Each env var object must contain key-value pairs for the \"name\" and \"value\" keys."
  }
  validation {
    condition     = length(var.rancher_additional_values) == 0 ? true : sum([for var in var.rancher_additional_values : 1 if length(lookup(var, "value", "")) > 0]) == length(var.rancher_additional_values)
    error_message = "Each env var object must contain key-value pairs for the \"name\" and \"value\" keys."
  }
}
