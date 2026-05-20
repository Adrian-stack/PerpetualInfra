include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/cdn.hcl"
  expose = true
}

# All cdn inputs are resolved by _envcommon/cdn.hcl via dependency blocks.
# domain_name and name_prefix come from the root inputs (env.hcl).
