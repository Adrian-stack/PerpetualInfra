# Root Terragrunt configuration.
# Every component in live/{env}/<component>/ includes this file via find_in_parent_folders().
# It generates backend.tf, providers.tf, and versions.tf for each component automatically.

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  environment        = local.env_vars.locals.environment
  aws_region         = local.env_vars.locals.aws_region
  name_prefix        = local.env_vars.locals.name_prefix
  availability_zone  = local.env_vars.locals.availability_zone
  notification_email = local.env_vars.locals.notification_email
  monthly_budget_usd = local.env_vars.locals.monthly_budget_usd

  # domain_name is optional (only prod defines it)
  domain_name = try(local.env_vars.locals.domain_name, "")
}

# ── Remote state ────────────────────────────────────────────────────────────
# Generates backend.tf per component.
# State key: {env}/{component}/terraform.tfstate
# e.g. prod/compute/terraform.tfstate
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket       = "perpetual-share-tfstate"
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}

# ── Provider generation ──────────────────────────────────────────────────────
# Both providers are generated for every component.
# The us_east_1 alias is required by the cdn module (ACM cert).
# Components that don't use it simply ignore it.
generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"

      default_tags {
        tags = {
          Project     = "perpetual-share"
          Environment = "${local.environment}"
          ManagedBy   = "terragrunt"
        }
      }
    }

    provider "aws" {
      alias  = "us_east_1"
      region = "us-east-1"

      default_tags {
        tags = {
          Project     = "perpetual-share"
          Environment = "${local.environment}"
          ManagedBy   = "terragrunt"
        }
      }
    }
  EOF
}

# ── Version pinning ──────────────────────────────────────────────────────────
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.10.0"

      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 5.0"
        }
        random = {
          source  = "hashicorp/random"
          version = "~> 3.0"
        }
      }
    }
  EOF
}

# ── Common inputs ────────────────────────────────────────────────────────────
# Passed to every component. Modules that don't declare these variables ignore them.
inputs = {
  environment        = local.environment
  name_prefix        = local.name_prefix
  aws_region         = local.aws_region
  region             = local.aws_region  # alias used by compute module
  availability_zone  = local.availability_zone
  notification_email = local.notification_email
  monthly_budget_usd = local.monthly_budget_usd
  domain_name        = local.domain_name
}
