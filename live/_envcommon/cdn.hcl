terraform {
  source = "${get_repo_root()}//infra/modules/cdn"
}

dependency "dns" {
  config_path = "../dns"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    zone_id                    = "Z0MOCK000000000"
    name_servers               = []
    domain_registration_status = "not-managed"
  }
}

dependency "storage" {
  config_path = "../storage"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    bucket_regional_domain_name = "mock.s3.eu-central-1.amazonaws.com"
  }
}

dependency "compute" {
  config_path = "../compute"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    public_dns = "ec2-0-0-0-0.eu-central-1.compute.amazonaws.com"
  }
}

inputs = {
  route53_zone_id           = dependency.dns.outputs.zone_id
  s3_bucket_regional_domain = dependency.storage.outputs.bucket_regional_domain_name
  ec2_public_dns            = dependency.compute.outputs.public_dns
}
