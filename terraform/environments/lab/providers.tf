provider "aws" {
  region              = var.region
  allowed_account_ids = [var.account_id]
  default_tags { tags = { Project = "aws-custody-security-lab", Domain = var.name } }
}
data "aws_caller_identity" "current" {}
check "correct_account" {
  assert {
    condition     = data.aws_caller_identity.current.account_id == var.account_id
    error_message = "Wrong account: use the independently governed credentials for this root."
  }
}
