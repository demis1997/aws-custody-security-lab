mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111", arn = "arn:aws:iam::111111111111:role/IndependentProvisioner", user_id = "synthetic" }
  }
}

variables {
  name                     = "custody-recovery"
  account_id               = "111111111111"
  deployment_acknowledged  = true
  bucket_name              = "synthetic-custody-recovery-111111111111"
  signer_runtime_arns      = { "custody-signer-a" = "arn:aws:iam::222222222222:role/custody-signer-a-runtime" }
  checkpoint_publisher_arn = "arn:aws:iam::333333333333:role/IndependentCheckpointPublisher"
  restore_reader_arns      = ["arn:aws:iam::444444444444:role/ReviewedRecoveryReader"]
}
run "recovery_roles_have_separate_capabilities" {
  command = plan
  assert {
    condition     = jsondecode(output.bucket_policy).Statement[1].Action == "s3:PutObject" && endswith(jsondecode(output.bucket_policy).Statement[1].Resource, "/backups/custody-signer-a/*")
    error_message = "Signer can publish only its own backups."
  }
  assert {
    condition     = endswith(jsondecode(output.bucket_policy).Statement[2].Resource, "/checkpoints/*") && jsondecode(output.bucket_policy).Statement[2].Principal.AWS != jsondecode(output.bucket_policy).Statement[1].Principal.AWS
    error_message = "Checkpoint authority must be separate from signer upload authority."
  }
  assert {
    condition     = !contains(jsondecode(output.bucket_policy).Statement[3].Action, "s3:DeleteObjectVersion")
    error_message = "Recovery readers must not delete retained history."
  }
}
run "recovery_requires_explicit_deployment_acknowledgment" {
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
