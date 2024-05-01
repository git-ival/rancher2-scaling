variable "num_projects" {
  type    = number
  default = 10
}

variable "num_namespaces" {
  type    = number
  default = 12
}

variable "num_secrets" {
  type    = number
  default = 100
}

variable "num_tokens" {
  type    = number
  default = 100
}

variable "num_users" {
  type    = number
  default = 300
}

variable "user_password" {
  type        = string
  description = "Password to use for created users"
  sensitive   = true
}
