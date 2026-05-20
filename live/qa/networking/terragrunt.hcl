include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/networking.hcl"
  expose = true
}

inputs = {
  cidr_block         = "10.1.0.0/16"
  public_subnet_cidr = "10.1.1.0/24"
}
