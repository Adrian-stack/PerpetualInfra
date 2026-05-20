include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/storage.hcl"
  expose = true
}

inputs = {
  cors_allowed_origins = ["https://perpetual-share.com", "https://www.perpetual-share.com"]
}
