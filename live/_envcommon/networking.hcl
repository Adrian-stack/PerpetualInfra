terraform {
  source = "${get_repo_root()}//modules/networking"
}

# No upstream dependencies. CIDR overrides are per-env.
