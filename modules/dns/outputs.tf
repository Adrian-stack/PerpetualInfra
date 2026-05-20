output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = local.zone_id
}

output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = local.name_servers
}

output "domain_registration_status" {
  description = "Domain registration status (ACTIVE once Route 53 completes registration)"
  value       = var.register_domain ? aws_route53_domains_registered_domain.main[0].registration_status : "not-managed"
}
