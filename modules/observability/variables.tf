variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (prod, qa)"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID to attach alarms to"
  type        = string
}

variable "notification_email" {
  description = "Email address for CloudWatch alarm and budget notifications"
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly cost budget cap in USD"
  type        = number
  default     = 10
}
