
variable "project_name" {
  type    = string
  default = "self-healing-storage"
}

variable "primary_region" {
  type    = string
  default = "ap-south-1"
}

variable "secondary_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "notification_email" {
  type        = string
  description = "Email address for SNS notifications"
}

variable "route53_domain_name" {
  type        = string
  description = "Existing Route 53 hosted zone domain"
  default     = ""
}

variable "environment" {
  type    = string
  default = "dev"
}
