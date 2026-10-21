mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111", arn = "arn:aws:iam::111111111111:role/IndependentProvisioner", user_id = "synthetic" }
  }
}

variables {
  name                    = "custody-security"
  account_id              = "111111111111"
  deployment_acknowledged = true
  bucket_name             = "synthetic-custody-audit-111111111111"
  trail_account_ids       = ["111111111111", "222222222222", "333333333333"]
  trail_names             = ["custody-signer-a", "custody-signer-b", "custody-signer-c"]
}
run "audit_delivery_is_service_and_source_bound" {
  command = plan
  assert {
    condition     = jsondecode(output.bucket_policy).Statement[1].Principal.Service == "cloudtrail.amazonaws.com" && length(jsondecode(output.bucket_policy).Statement[1].Condition.ArnEquals["aws:SourceArn"]) == 9
    error_message = "CloudTrail delivery must be service bound and constrained to declared source trails."
  }
  assert {
    condition     = jsondecode(output.bucket_policy).Statement[0].Effect == "Deny" && jsondecode(output.bucket_policy).Statement[0].Condition.Bool["aws:SecureTransport"] == "false"
    error_message = "Evidence storage must deny plaintext transport."
  }
}
run "audit_requires_explicit_deployment_acknowledgment" {
  command = plan
  variables { deployment_acknowledged = false }
  expect_failures = [var.deployment_acknowledged]
}

run "locked_private_versioned_evidence" {
  command = plan
  assert {
    condition     = output.retention_contract.mode == "COMPLIANCE" && output.retention_contract.days >= 30 && output.retention_contract.versioning == "Enabled" && output.retention_contract.public_block && !output.retention_contract.force_destroy
    error_message = "Evidence needs compliance retention, versioning, private access and no forced destruction."
  }
}
