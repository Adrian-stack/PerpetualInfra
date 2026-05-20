variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (prod, qa)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for the EC2 instance"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the EC2 instance"
  type        = string
}

variable "availability_zone" {
  description = "AZ for the EBS data volume (must match subnet AZ)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (t3.micro for free tier)"
  type        = string
  default     = "t3.micro"
}

variable "s3_bucket_arn" {
  description = "ARN of the uploads S3 bucket"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the uploads S3 bucket"
  type        = string
}

variable "image_uri" {
  description = "Docker image URI to run (ECR or Docker Hub)"
  type        = string
  default     = "ghcr.io/placeholder/perpetual-share:latest"
}

variable "data_volume_size_gb" {
  description = "Size in GB of the EBS data volume for SQLite"
  type        = number
  default     = 8
}
