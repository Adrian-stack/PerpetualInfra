include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/observability.hcl"
  expose = true
}

# notification_email and monthly_budget_usd come from root inputs (env.hcl).
