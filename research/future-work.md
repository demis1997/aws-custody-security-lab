# Future work

1. Review actual account ownership, bootstrap roles, independent state backends, artifact approval and CA governance. Obtain explicit deployment and cost approval before any AWS access or apply.
2. Replace placeholder images/principals with reviewed values; run real IAM Access Analyzer and isolated policy simulation; validate per-domain peering routes and deny tests.
3. Integrate the pinned Quorum Custody native adapter, independently approved builds, mTLS, PostgreSQL state and a private RPC proxy. Record each protocol/persistence boundary reached by tests.
4. Exercise CloudTrail cross-account delivery, digest verification, Flow Logs, GuardDuty findings and incident triage. Add Config only for deployed drift questions with an owner and budget.
5. Implement signed checkpoint publication, independent latest-record selection and reviewed restore execution; test Object Lock behavior and live nonce/budget reconciliation with different administrators.
6. Build a KMS/CloudHSM/Nitro capability matrix from actual protocol operations and APIs. Separate wrapping from hardware-resident threshold computation; reject unsupported designs rather than relabeling them.
7. Investigate hybrid post quantum contract authorization, bounded verifiers, ERC-4337, upgrade/recovery authority and EOA migration as a separate research track. No implementation claim is made for those proposals.
