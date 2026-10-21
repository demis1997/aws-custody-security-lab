# Attack scenario matrix

The complete prerequisites, assets, boundary, defense, test, expected result and residual risk are recorded in [the machine-readable matrix](attack-scenarios.json). “Model” and “mocked plan” are evidence levels, not cloud exploit results.

| Scenario | Expected result | Executed evidence | Remaining risk |
| --- | --- | --- | --- |
| compromised-signer-a | No quorum | Model: blocked | Live host still controls one share |
| compromised-coordinator | No new unauthorized issuance | Model: blocked | Already issued bytes remain portable; no live RPC test here |
| stolen-iam-role | No B access | Model: blocked | Real IAM evaluation and credential theft not executed |
| compromised-ci | Unsafe shared authority defeats isolation | Model: quorum controlled | Terraform cannot prove human release independence |
| malicious-admin | One domain remains insufficient | Model: no quorum | Two domain admins or common account recovery defeat assumption |
| cross-account-escalation | Blocked without declared edge | Model + exact-trust Terraform assertions | No live AssumeRole or Access Analyzer run |
| compromised-recovery-operator | Reject one approver | Model: recovery-quorum rejection | Two-person approval is modeled, not enforced by S3 |
| checkpoint-rollback | Reject stale pair | Model: stale-checkpoint rejection | Joint trusted-anchor rollback permits replay |
| kms-policy-compromise | One key insufficient; two key domains sufficient | Model: expected boundary | No actual KMS grant/decryption API call |
| unauthorized-approval | Reject partial approval | Model: blocked | Both approval keys can misrepresent intent within policy |
| network-isolation-failure | Reject unsafe configuration | Mocked Terraform plan: rejected | Packet-level isolation/mTLS not tested |
| audit-log-tampering | Retention/private access configured | Mocked resource assertions; S3 delete Not Executed | Management, retention expiry, delivery and validation still matter |
| quorum-availability | One loss accepted; two fail closed | Model: matched both outcomes | No native timeout, restart, DKG or AWS outage exercise |
| organizations-management | Only shared member admin trust yields quorum path | Model: both cases matched | Management can remove SCPs; other billing/provider paths remain |
