variable "domain_name" {
  description = "Primary domain name (e.g. perpetual-share.com)"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "create_zone" {
  description = "Create a new Route 53 hosted zone. Set false to look up an existing zone."
  type        = bool
  default     = true
}

variable "register_domain" {
  description = "Purchase and register the domain via Route 53. Only enable for prod. Requires contact variables."
  type        = bool
  default     = false
}

# ── Registrant contact info (required when register_domain = true) ───────────

variable "registrant_first_name" {
  description = "Registrant first name"
  type        = string
  default     = ""
}

variable "registrant_last_name" {
  description = "Registrant last name"
  type        = string
  default     = ""
}

variable "registrant_email" {
  description = "Registrant email address"
  type        = string
  default     = ""
}

variable "registrant_phone" {
  description = "Registrant phone in E.164 format: +CountryCode.Number (e.g. +40.742000000)"
  type        = string
  default     = ""
}

variable "registrant_address_line_1" {
  description = "Registrant street address"
  type        = string
  default     = ""
}

variable "registrant_city" {
  description = "Registrant city"
  type        = string
  default     = ""
}

variable "registrant_state" {
  description = "Registrant state or county (leave empty if not applicable)"
  type        = string
  default     = ""
}

variable "registrant_country_code" {
  description = "Two-letter ISO country code (e.g. RO for Romania)"
  type        = string
  default     = "RO"
}

variable "registrant_zip_code" {
  description = "Registrant postal code"
  type        = string
  default     = ""
}
