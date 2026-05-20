terraform {
  source = "${get_repo_root()}//infra/modules/networking"
}

# No upstream dependencies. CIDR overrides are per-env.
