variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (prod, qa)"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name (e.g. perpetual-share.com)"
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID — used for ACM validation records and A aliases"
  type        = string
}

variable "s3_bucket_regional_domain" {
  description = "S3 bucket regional domain name for the CloudFront S3 origin"
  type        = string
}

variable "ec2_public_dns" {
  description = "EC2 instance public DNS for the CloudFront EC2 origin"
  type        = string
}
