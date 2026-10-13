variable "subscription_id" {
  type        = string
  description = "Azure subscription ID. Get it with: az account show --query id -o tsv"
}

variable "location" {
  type    = string
  default = "westus2"
}

variable "project" {
  type    = string
  default = "data"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "databricks_sku" {
  type    = string
  default = "premium" # standard | premium | trial
}

variable "postgres_sku" {
  type    = string
  default = "B_Standard_B1ms" # smallest burstable tier, low cost for learning
}

variable "budget_amount" {
  type    = number
  default = 100
}

variable "budget_start_date" {
  type        = string
  default     = "2026-11-01T00:00:00Z"
  description = "Must be the first day of a month."
}

variable "budget_end_date" {
  type    = string
  default = "2027-10-31T00:00:00Z"
}

variable "alert_emails" {
  type        = list(string)
  description = "Addresses that receive budget alerts."
}

variable "users" {
  type = map(object({
    display_name = string
    department   = string
  }))
  default     = {}
  description = "Entra ID users to create and add to the data team group."
}

variable "my_ip" {
  type        = string
  default     = ""
  description = "Your public IP, so you can connect to Postgres from your machine. Leave empty to skip."
}
