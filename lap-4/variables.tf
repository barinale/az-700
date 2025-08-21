variable "subscription_id" {
  type = string
  description = "The Azure subscription ID to deploy resources into."
}

variable "admin_password" {
  description = "Admin password for the Linux VM"
  type        = string
  sensitive   = true
}