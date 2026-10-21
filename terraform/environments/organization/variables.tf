variable "name" {
  type = string
}
variable "account_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "Use the expected 12 digit account ID."
  }
}
variable "region" {
  type    = string
  default = "eu-central-1"
}
variable "deployment_acknowledged" {
  type    = bool
  default = false
  validation {
    condition     = var.deployment_acknowledged
    error_message = "This is billable infrastructure. Explicitly acknowledge an independently approved lab deployment first."
  }
}
