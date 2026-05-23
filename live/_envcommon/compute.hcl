terraform {
  source = "${get_repo_root()}//modules/compute"
}

dependency "networking" {
  config_path = "${get_original_terragrunt_dir()}/../networking"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    public_subnet_id      = "subnet-00000000"
    app_security_group_id = "sg-00000000"
    availability_zone     = "eu-central-1a"
  }
}

dependency "storage" {
  config_path = "${get_original_terragrunt_dir()}/../storage"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    bucket_arn  = "arn:aws:s3:::mock-bucket"
    bucket_name = "mock-bucket"
  }
}

inputs = {
  instance_type       = "t3.micro"
  data_volume_size_gb = 8
  subnet_id           = dependency.networking.outputs.public_subnet_id
  security_group_id   = dependency.networking.outputs.app_security_group_id
  s3_bucket_arn       = dependency.storage.outputs.bucket_arn
  s3_bucket_name      = dependency.storage.outputs.bucket_name
}
