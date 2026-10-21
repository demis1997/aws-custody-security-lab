# IAM and deployment authority

The workload runtime trusts only `ec2.amazonaws.com`. It has no `sts:AssumeRole`, `iam:PassRole`, role-policy mutation, KMS policy mutation, grant creation, S3 deletion or checkpoint publication permission in this configuration. Signer backup access is limited to `s3:PutObject` under `backups/<domain>/`. KMS envelope permissions are granted directly to the exact runtime role in that key's resource policy and require both domain and purpose encryption context.

Exact operator principals may assume a per-domain operator role only with an MFA context. **No StartSession, SendCommand or other operator action permission is attached.** This avoids quietly giving a common support operator a live signer shell. A reviewed break-glass policy must target the intended instance and session document and be approved within that domain. The MFA condition targets AWS MFA session context; a federated identity provider may need a separately reviewed assurance design. Do not assume an Identity Center session automatically supplies that condition.

Bootstrap `IndependentProvisioner` and `IndependentKeyAdmin` roles are prerequisites owned by each domain. They are not created with broad trust here. Key administrators can replace a key policy and therefore may grant themselves decryption: key policy administration is a custody capability. There is no claim that key admin and key user are adversarially independent solely because their current statements differ.

Separate write-only backup publishers, checkpoint publisher and restore readers appear in recovery bucket policy. S3 grants read access; it does not enforce the model's two-person restore approval or trusted-latest check. Those remain application/runbook integration work. Restoring a file is not automatically restoring a safe signer.

## Necessary wildcard exceptions

- KMS resource-policy `Resource: "*"` denotes the key to which that policy is attached; principals and actions are explicit. It is not an identity policy granting all KMS keys.
- SSM Messages channel operations and `ssm:UpdateInstanceInformation` use `Resource: "*"` because the selected runtime operations do not support the desired per-instance resource scoping. They grant agent transport, not permission for a human to start a session.
- The VPC Flow Logs role uses `logs:DescribeLogGroups` on `*`; log stream writing is scoped to its own group.
- S3's explicit plaintext-transport **Deny** uses `Principal: "*"` and `s3:*` to cover every insecure operation. Allow statements remain bounded.
- SCP Deny statements use `Resource: "*"` to apply their guardrails to member-account resources. This is not an Allow grant.
- Log stream ARN suffixes and object key suffixes intentionally cover streams/objects within a named log group or bucket prefix.

## Software authority

There is no shared privileged deployment workflow. Terraform execution, image promotion, signer software approval and certificate enrollment must be governed separately per domain. A common build system may produce an artifact, but each domain must independently review and authorize its release. The local authority graph includes an unsafe shared-deployer counterexample; that edge is not created by Terraform.

Live IAM simulation, Access Analyzer policy validation, cross-account role-assumption attempts and organization bootstrap are **Not Executed**. Mocked Terraform tests inspect generated policies; they do not evaluate all AWS identity/resource/SCP/permission-boundary interactions.
