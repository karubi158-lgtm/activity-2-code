variable "bucket_name" {
  type = string
}

variable "region" {
  type = string
}

variable "peer_bucket_name" {
  type = string
}

variable "peer_region" {
  type = string
}

variable "healing_enabled" {
  type = bool
}

variable "reconcile_schedule" {
  type = string
}
