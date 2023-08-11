variable "kube_config_path" {
  default     = null
  type        = string
  description = "Path to kubeconfig file on local machine"
}

variable "release_prefix" {
  default     = ""
  type        = string
  description = "Prefix to append to the name of each helm_release"
}

variable "num_charts" {
  default     = 1
  type        = number
  description = "Number of deployments to do for the specified chart"
}

variable "local_chart_path" {
  default     = null
  type        = string
  description = "Path to helm chart folder on local machine"
}

variable "namespace" {
  default     = null
  type        = string
  description = "Namespace to deploy helm chart into"
}

variable "values" {
  default     = null
  type        = string
  description = "Path to helm chart's values.yaml file"
}
