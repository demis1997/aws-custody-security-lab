# Limitations

**Not Executed:** real AWS plan/apply, account/role authentication, resource deployment, IAM Access Analyzer or policy simulator, cross-account STS attempts, real network/mTLS traffic, CloudTrail delivery/verification, S3 Object Lock deletion, Config/GuardDuty findings, cloud recovery, failover timing, paid hardware tests, native cb-mpc DKG/signing, Ethereum submission, or post quantum cryptographic integration.

Terraform mock providers return synthetic computed values and do not validate remote existence, permissions, delivery, regional support, quotas, AMI correctness or service interoperability. The input examples intentionally contain placeholders and require real design/ownership review. Source validation is not a penetration test.

Python's HMAC fixtures provide local message/snapshot integrity. They do not model asymmetric trust perfectly, implement threshold cryptography, or prove distributed consensus. Authority edges are explicit assumptions; shared control cases demonstrate the consequence of those assumptions, not newly discovered AWS vulnerabilities. Two-person restore approval is model logic and proposed application governance, not an S3 property.

Some broad policy selectors are required for service APIs or explicit Deny coverage; each is described in architecture/iam-design.md. Key-policy administration, bootstrap/deployment roles, state backends and operating systems remain high privilege. The independent deployment/recovery operating model is documented but has not been exercised with separate administrators.

The workload EC2 hosts are infrastructure shells without custody software, certificates, shares, database or RPC proxy. There is no production deployment. No cloud resources were created or costs incurred by local validation. Checkov, Trivy and TFLint were not run; the implemented equivalent policy checks are Terraform plan assertions plus local static publication/security checks.
