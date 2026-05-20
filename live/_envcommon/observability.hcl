terraform {
  source = "${get_repo_root()}//infra/modules/observability"
}

dependency "compute" {
  config_path = "../compute"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    instance_id = "i-00000000"
  }
}

inputs = {
  instance_id = dependency.compute.outputs.instance_id
}
