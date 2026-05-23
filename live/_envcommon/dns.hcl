terraform {
  source = "${get_repo_root()}//modules/dns"
}

# dns is a root component — no upstream dependencies.
inputs = {
  create_zone     = true
  register_domain = false  # overridden to true in prod only
}
