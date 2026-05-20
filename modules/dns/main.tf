resource "aws_route53_zone" "main" {
  count = var.create_zone ? 1 : 0
  name  = var.domain_name

  tags = {
    Name        = var.domain_name
    Environment = var.environment
  }
}

data "aws_route53_zone" "main" {
  count = var.create_zone ? 0 : 1
  name  = var.domain_name
}

locals {
  zone_id      = var.create_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.main[0].zone_id
  name_servers = var.create_zone ? aws_route53_zone.main[0].name_servers : data.aws_route53_zone.main[0].name_servers
}

# Domain registration via Route 53.
# Enabled only when register_domain = true (prod env).
# Privacy protection hides WHOIS contact details.
# NOTE: destroying this resource in Terraform does NOT cancel the domain registration —
# domain cancellations must be handled through the AWS console.
resource "aws_route53_domains_registered_domain" "main" {
  count       = var.register_domain ? 1 : 0
  domain_name = var.domain_name
  auto_renew  = true

  privacy_protect_registrant_contact = true
  privacy_protect_admin_contact      = true
  privacy_protect_tech_contact       = true

  # Wire the registration to use our explicitly created hosted zone NS records,
  # so Route 53 updates the registrar NS records automatically — no manual step needed.
  dynamic "name_server" {
    for_each = local.name_servers
    content {
      name = name_server.value
    }
  }

  registrant_contact {
    first_name     = var.registrant_first_name
    last_name      = var.registrant_last_name
    email          = var.registrant_email
    phone_number   = var.registrant_phone
    address_line_1 = var.registrant_address_line_1
    city           = var.registrant_city
    state          = var.registrant_state
    country_code   = var.registrant_country_code
    zip_code       = var.registrant_zip_code
  }

  admin_contact {
    first_name     = var.registrant_first_name
    last_name      = var.registrant_last_name
    email          = var.registrant_email
    phone_number   = var.registrant_phone
    address_line_1 = var.registrant_address_line_1
    city           = var.registrant_city
    state          = var.registrant_state
    country_code   = var.registrant_country_code
    zip_code       = var.registrant_zip_code
  }

  tech_contact {
    first_name     = var.registrant_first_name
    last_name      = var.registrant_last_name
    email          = var.registrant_email
    phone_number   = var.registrant_phone
    address_line_1 = var.registrant_address_line_1
    city           = var.registrant_city
    state          = var.registrant_state
    country_code   = var.registrant_country_code
    zip_code       = var.registrant_zip_code
  }
}
