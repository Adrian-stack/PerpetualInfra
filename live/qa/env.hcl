locals {
  environment        = "qa"
  aws_region         = "eu-central-1"
  name_prefix        = "perpetual-share-qa"
  availability_zone  = "eu-central-1a"
  notification_email = "adimoldovan28@gmail.com"
  monthly_budget_usd = 5
  # No domain_name — QA is accessed via EC2 Elastic IP directly
}
