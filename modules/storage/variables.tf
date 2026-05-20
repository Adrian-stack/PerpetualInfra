variable "bucket_name" {
  description = "S3 bucket name for photo uploads"
  type        = string
}

variable "environment" {
  description = "Deployment environment (prod, qa)"
  type        = string
}

variable "cors_allowed_origins" {
  description = "Origins allowed for CORS PUT/GET (e.g. CloudFront domain or * for QA)"
  type        = list(string)
}
