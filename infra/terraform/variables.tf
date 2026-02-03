variable "project_name" {
  type        = string
  description = "Short name used for resource naming"
  default     = "azure-3-tier"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "canadacentral"
}
variable "cicd_sp_object_id" {
  type        = string
  description = "Object ID of CI Service Principal (used for AcrPush)."
}

variable "web_image_name" {
  type        = string
  description = "Container image name for web"
  default     = "web"
}

variable "api_image_name" {
  type        = string
  description = "Container image name for api"
  default     = "api"
}
variable "api_image_tag" {
  type    = string
  default = "bootstrap"
}

variable "web_image_tag" {
  type    = string
  default = "bootstrap"
}

variable "db_admin_user" {
  type    = string
  default = "pgadmin"
}


variable "db_name" {
  type    = string
  default = "appdb"
}
variable "db_admin_password" {
  type      = string
  sensitive = true
}
