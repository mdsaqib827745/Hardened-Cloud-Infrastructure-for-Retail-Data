variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-retail-hardened-prod"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "centralindia"
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "sql_admin_login" {
  description = "Admin login for SQL Server"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "Admin password for SQL Server"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd123456!" # Change this!
}
