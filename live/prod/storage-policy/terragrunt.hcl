include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}//modules/storage-policy"
}

dependency "storage" {
  config_path = "../storage"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    bucket_id  = "mock-bucket"
    bucket_arn = "arn:aws:s3:::mock-bucket"
  }
}

dependency "cdn" {
  config_path = "../cdn"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    distribution_arn = "arn:aws:cloudfront::000000000000:distribution/MOCK"
  }
}

inputs = {
  bucket_id                   = dependency.storage.outputs.bucket_id
  bucket_arn                  = dependency.storage.outputs.bucket_arn
  cloudfront_distribution_arn = dependency.cdn.outputs.distribution_arn
}
