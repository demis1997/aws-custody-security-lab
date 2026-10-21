# AWS service decisions

| Component | Implementation/evaluation | Threat addressed and remaining boundary |
| --- | --- | --- |
| IAM | Runtime roles, exact operator trust and scoped policies | Limits routine permissions; administrator/release authority can still replace controls. |
| Organizations / SCP | Separate optional management root and OU attachment | Restricts selected member operations; management can remove it and is not constrained by it. |
| VPC / private subnet / security groups | Implemented per workload root, no IGW/NAT/public workload IP or SSH | Restricts reachability; peer routes and mTLS identity still require separate configuration. |
| VPC endpoints | SSM, SSM Messages, Logs, KMS and prefix-limited S3 gateway | Private AWS API paths; endpoint policies do not replace IAM or stop an authorized compromised host. |
| KMS | Signer envelope key, context binding, rotation, explicit key administration | Protects stored envelopes; live authorized plaintext and key-policy administration remain in scope. |
| CloudHSM | Evaluated, not provisioned | Protocol/API compatibility unproven; no claim of hardware-resident threshold ECDSA. |
| Secrets Manager | Evaluated, deferred | No defined deployed secret lifecycle yet; no unused secret or endpoint is provisioned for decoration. |
| CloudTrail | Account trails, digest validation, cross-account S3 delivery policy | Tracks control-plane actions; delivery and independent validation not exercised. |
| AWS Config | Evaluated, deferred | Continuous deployed-state drift inventory is useful after deployment; not added to an unprovisioned lab. |
| GuardDuty | Optional per-workload-account detector, default enabled | Threat detection, not prevention; no organization enrollment or observed finding is claimed. |
| S3 versioning / Object Lock | Audit and recovery stores, 30-day COMPLIANCE retention | Preserves versions; does not decide current authorization history. Retention incurs durable cost. |
| EventBridge | Authority-change rules to a scoped CloudWatch log target | Makes selected changes observable; triage ownership and external paging remain operational work. |
| CloudWatch | Scoped log groups, retention and VPC flow logging | Enables evidence capture; no workload log agent is installed or runtime logs demonstrated. |
| Systems Manager | Private endpoints and agent transport permissions | Prepares private management; no human session grant or agent installation is performed. |
| Nitro Enclaves | Optional future research | Attested envelope release could narrow host exposure, subject to protocol, side-channel and recovery analysis. Not implemented. |
| Ethereum RPC | Explicit private proxy CIDR path for coordinator only | No public Internet egress by default; RPC proxy, chain connectivity and finality integration remain unimplemented. |

Provisioning any of the implemented resources can incur charges. A resource definition and mocked plan are not proof of successful deployment or control effectiveness.
