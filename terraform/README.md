# Terraform roots and deployment prerequisites

Terraform **1.9.8**, AWS provider **5.100.0**, exact constraints and committed dependency lockfiles. The safe validation command is `bash scripts/validate.sh` from repository root. It runs `terraform init -backend=false`, validate, and **mocked, plan-only** tests. No real plan or apply is part of validation.

## Separate roots

- `environments/lab`: one signer, coordinator or authorization domain, selected by `kind`. Use independent account credentials and independently controlled state per invocation. Example A/B/C, coordinator and authorization tfvars files are in `examples/`.
- `environments/security`: audit bucket and bounded CloudTrail delivery policy. Precreate this before workload trails. The supplied account/trail sets form the explicitly allowed source ARN combinations.
- `environments/recovery`: retained backup/checkpoint store and distinct publisher/reader principals.
- `environments/organization`: optional SCP in a pre-existing management account and OU. Test its effect independently before any attachment.

No accounts, bootstrap administrator roles, Terraform backend, shared deployment role, CA, MPC executable, database, Ethereum node or RPC proxy are created. IAM principal ARNs used in KMS/S3 policies must already exist. AWS may reject nonexistent principals: mocks do not test that existence.

## After a separately approved deployment

Do not apply these examples unchanged. Account IDs, bucket names, AMI IDs, principal ARNs and peer identifiers are synthetic placeholders. Workload networks are limited to 10/8 private IPv4 space, with a /16 through /24 VPC; peers use explicit private ranges. Select a supported, patched AMI in the target region and arrange a reviewed offline artifact/agent installation path. There is no Internet package installation route.

Create isolated per-domain working directories and protected remote state backends before real planning. Pin and review module content. Confirm every key administrator can safely recover its own key policy and that the provisioner is included without enabling a common cross-domain operator. Review the default single-subnet/AZ topology: this is not a high-availability deployment.

A future reviewed sequence is audit/recovery dependencies, per-domain identity/network/host modules, two-sided peering approval and reverse routes, then independent application/CA installation. `deployment_acknowledged` defaults to false and must be explicitly set only after account ownership, costs and operational approval are established. The flag is a misuse guard, not a substitute for approval.

For a **future approved plan**, use a dedicated domain directory and its own credentials:

```sh
terraform init
terraform plan -var-file=/path/to/reviewed-domain.tfvars
```

No apply command is included in automation. Applying, SCP attachment, SSM access grants and any AWS/HSM experiments require separate approval. This mission did not authorize cloud charges.

## Cost and cleanup

EC2/EBS, interface endpoints per account/AZ, KMS, CloudTrail, GuardDuty, CloudWatch and retained S3 objects can cost money. No dollar estimate is invented here. Obtain region-specific estimates and budget/alert ownership before provisioning. The evidence buckets use COMPLIANCE retention and Terraform destruction protection; retained objects may prevent cleanup and continue to incur cost. Do not remove those controls merely to make destroy convenient. Read [Object Lock semantics](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html).

No live AWS identity checks, plans, apply, deployment smoke tests, resource deletion, IAM Access Analyzer, or cloud charges were executed or incurred by this repository's validation.
