include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/compute.hcl"
  expose = true
}

# All compute inputs covered by envcommon deps and root inputs.
# Override image_uri here once you have an ECR URI:
# inputs = {
#   image_uri = "123456789012.dkr.ecr.eu-central-1.amazonaws.com/perpetual-share:qa"
# }
