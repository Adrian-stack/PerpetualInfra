include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/dns.hcl"
  expose = true
}

inputs = {
  register_domain = true

  # ── Registrant contact info ────────────────────────────────────────────────
  # Used for WHOIS registration. Privacy protection is enabled so these details
  # are hidden from public WHOIS lookups.
  #
  # Phone format: +CountryCode.Number  e.g. +40.742123456
  # Country code: two-letter ISO       e.g. RO
  #
  # Fill in your real details before running `terragrunt apply`.
  registrant_first_name     = "Adi"
  registrant_last_name      = "Moldovan"
  registrant_email          = "adimoldovan28@gmail.com"
  registrant_phone          = "+40.XXXXXXXXX"   # replace with your phone number
  registrant_address_line_1 = "REPLACE_WITH_ADDRESS"
  registrant_city           = "REPLACE_WITH_CITY"
  registrant_state          = ""                # leave empty for Romania
  registrant_country_code   = "RO"
  registrant_zip_code       = "REPLACE_WITH_ZIP"
}
