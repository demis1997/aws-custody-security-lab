# Findings and evidence levels

1. **Independent account labels do not survive shared deployment control.** The authority graph's common deployer reaches all three signer hosts; one isolated deployer reaches one. This is an executed graph/model result, not an AWS escalation demonstration.
2. **Authorization compromise and signing compromise differ.** One signer cannot reach the quorum. Two compromised signing domains can. A service holding both approval keys can authorize dishonest intent inside the standing signer policy, while an out-of-policy recipient remains rejected in the model.
3. **Recovery integrity needs trusted recency.** Current anchors reject stale backup pairs and missing checkpoints. When both snapshot and trusted-latest anchor roll back, a consumed approval is reusable in the synthetic state model. Encryption or retention alone does not resolve that selection problem.
4. **IAM/KMS/S3 policy intent is testable before deployment.** Mocked Terraform plan assertions inspect actual generated policies and resource settings, including no public workload IP, IMDSv2, bound KMS context, upload-only backup scope, separate checkpoint writer and retained evidence. These checks are narrower than AWS enforcement.
5. **Organizations authority must be modeled precisely.** Removing an SCP is different from owning a member administrator. The model distinguishes management alone from management with an existing member-admin trust path.

The source reference is Quorum Custody `691e253ccdc2756afe215a23384eb72e2d4fde3c`. The linked paper supplies prior application/Anvil evidence; this repository does not rerun or relabel it as AWS/MPC evidence. See VALIDATION_REPORT.md for executed commands and counts.
