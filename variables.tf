# variables.tf

variable "az_counter" {
  description = "Quantity of AZs in region"
  default     = "2"
  }

variable "health_check_path" {
 default = "/"
 }