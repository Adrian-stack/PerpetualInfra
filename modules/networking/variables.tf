variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (prod, qa)"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "AZ for the public subnet (must match EBS volume AZ)"
  type        = string
}
