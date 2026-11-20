variable "region_a" {
  type    = string
  default = "us-east-1"
}

variable "region_b" {
  type    = string
  default = "us-west-2"
}

variable "bucket_prefix" {
  type        = string
  default     = "self-healing"
  description = "Buckets become <prefix>-<region>-<account-id>"
}

variable "healing_enabled" {
  type        = bool
  default     = true
  description = "Set false (and apply) BEFORE terraform destroy, otherwise the healer recreates what you delete."
}

variable "reconcile_schedule" {
  type    = string
  default = "rate(5 minutes)"
}

variable "access_code" {
  type        = string
  sensitive   = true
  description = "Shared access code for the dashboard. Set it in terraform.tfvars (git-ignored)."
}
