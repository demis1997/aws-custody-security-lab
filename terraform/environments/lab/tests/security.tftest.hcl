mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111", arn = "arn:aws:iam::111111111111:role/IndependentProvisioner", user_id = "synthetic" }
  }
}
variables {
  name                    = "custody-signer-a"
  account_id              = "111111111111"
  kind                    = "signer"
  cidr                    = "10.10.0.0/16"
  ami_id                  = "ami-0123456789abcdef0"
  operator_arns           = ["arn:aws:iam::111111111111:user/LabHuman"]
  key_admin_arns          = ["arn:aws:iam::111111111111:role/IndependentProvisioner"]
  audit_bucket_name       = "synthetic-audit-evidence-111111111111"
  recovery_bucket_name    = "synthetic-recovery-evidence-111111111111"
  deployment_acknowledged = true
}

run "private_host_and_bound_keys" {
  command = plan
  assert {
    condition     = !output.host_security.public_ip && output.host_security.imds_tokens == "required" && output.host_security.hop_limit == 1 && output.host_security.encrypted
    error_message = "Workload must have no public IP, require IMDSv2, restrict metadata hops and encrypt root storage."
  }
  assert {
    condition     = jsondecode(output.key_policy).Statement[1].Condition.StringEquals["kms:EncryptionContext:custody:domain"] == "custody-signer-a"
    error_message = "Envelope decryption must bind the exact custody domain."
  }
  assert {
    condition     = !contains(jsondecode(output.key_policy).Statement[1].Action, "kms:CreateGrant") && !contains(jsondecode(output.key_policy).Statement[1].Action, "kms:PutKeyPolicy")
    error_message = "Runtime cannot delegate key access or administer its own key policy."
  }
  assert {
    condition     = jsondecode(output.operator_trust).Statement[0].Condition.Bool["aws:MultiFactorAuthPresent"] == "true"
    error_message = "Human operator role requires MFA context."
  }
  assert {
    condition     = jsondecode(output.backup_policy).Statement[0].Action == ["s3:PutObject"] && endswith(jsondecode(output.backup_policy).Statement[0].Resource, "/backups/custody-signer-a/*")
    error_message = "Signer must have only write access to its own backup prefix."
  }
}
run "reject_unacknowledged_deployment" {
  command = plan
  variables { deployment_acknowledged = false }
  expect_failures = [var.deployment_acknowledged]
}
run "reject_world_peer" {
  command = plan
  variables { peer_cidrs = ["0.0.0.0/0"] }
  expect_failures = [var.peer_cidrs]
}
run "reject_wildcard_operator" {
  command = plan
  variables { operator_arns = ["*"] }
  expect_failures = [var.operator_arns]
}
run "coordinator_has_no_signer_backup_policy" {
  command = plan
  variables { kind = "coordinator" }
  assert {
    condition     = output.backup_policy == null && output.key_policy == null
    error_message = "Coordinator must not inherit signer backup privileges."
  }
}

run "reject_public_half_internet_peer" {
  command = plan
  variables { peer_cidrs = ["0.0.0.0/1"] }
  expect_failures = [var.peer_cidrs]
}
run "reject_public_workload_network" {
  command = plan
  variables { cidr = "8.8.0.0/16" }
  expect_failures = [var.cidr]
}

run "reject_unapproved_peer_route" {
  command = plan
  variables {
    requested_peers = { bad = { account_id = "222222222222", vpc_id = "vpc-0123456789abcdef0", cidr = "0.0.0.0/0" } }
  }
  expect_failures = [var.requested_peers]
}
run "explicit_cross_account_peer_routes_plan" {
  command = plan
  variables {
    peer_cidrs           = ["10.20.0.0/16", "10.30.0.0/16"]
    requested_peers      = { b = { account_id = "222222222222", vpc_id = "vpc-0123456789abcdef0", cidr = "10.20.0.0/16" } }
    accepted_peering_ids = { "10.30.0.0/16" = "pcx-0123456789abcdef0" }
  }
}
