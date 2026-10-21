mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111", arn = "arn:aws:iam::111111111111:role/IndependentProvisioner", user_id = "synthetic" }
  }
}

variables {
  name                    = "custody-org"
  account_id              = "111111111111"
  deployment_acknowledged = true
  target_ou_id            = "ou-abcd-12345678"
}
run "guardrail_configuration_plans" { command = plan }
run "guardrails_require_explicit_deployment_acknowledgment" {
  command = plan
  variables { deployment_acknowledged = false }
  expect_failures = [var.deployment_acknowledged]
}
