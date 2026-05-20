variable "bucket_id" {
  description = "S3 bucket ID to attach the policy to"
  type        = string
}

variable "bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN to scope the OAC bucket policy"
  type        = string
}
