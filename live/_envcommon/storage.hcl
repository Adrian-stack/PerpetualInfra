terraform {
  source = "${get_repo_root()}//infra/modules/storage"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# No cdn dependency here — storage-policy is a separate component that depends on
# both storage and cdn, breaking the circular dependency.
inputs = {
  bucket_name = "${local.env_vars.locals.name_prefix}-uploads"
}
