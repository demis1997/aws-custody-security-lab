# Recovery and trusted history

![Disaster recovery](diagrams/disaster-recovery.svg)

The recovery module stores encrypted application backups and checkpoint objects under different write authorities. COMPLIANCE retention and versioning preserve retained versions. `force_destroy=false` and `prevent_destroy` prevent casual Terraform cleanup. They are not protection against all privileged administration, account closure, loss of decryption capability, or choosing an obsolete retained version.

The local recovery model records policy epoch, nonce, spent budget, consumed request IDs, generation and a snapshot digest. An independent synthetic checkpoint authority attests the digest. Restore requires two declared recovery approvals, a valid attestation, a matching snapshot and equality with the independently held trusted-latest checkpoint. Missing evidence fails closed. This is an executable model, not a deployed AWS restore service.

Tests cover stale signer backup, matching stale checkpoint, old policy epoch, consumed-approval replay, one/two signer loss, valid current restoration, missing checkpoint, one compromised recovery approver, forged evidence and joint rollback. The joint state-plus-trusted-anchor case intentionally succeeds and permits replay, showing precisely which assumption was lost.

## Proposed operational drill

1. Pause new issuance and reconcile known signed bytes with chain observations; an application freeze cannot recall an ordinary signed transaction already held elsewhere.
2. Identify a surviving signing quorum, trusted policy epoch, reserved spending/nonce history and current independent checkpoint. Preserve evidence; do not reset counters to make a restore pass.
3. Obtain independent restore approval, read an exact retained backup version, and verify payload hash and authoritative checkpoint selection before mounting signer state.
4. Restore into an isolated domain, rotate transport/operator credentials and validate participant identities. Reconcile ambiguous sessions and broadcasts before enabling new issuance.
5. Record recovery time, lost work, residual signed authority and any compromised administrator paths. If both state and independent anchor are suspect, follow an asset migration/incident decision rather than silently trusting the old pair.

The upload client must supply an appropriate checksum when using S3 Object Lock; see [AWS upload requirements](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock-managing.html). No uploader, native restore, CloudTrail delivery, Object Lock delete attempt, multi-region recovery or measured RPO/RTO exercise was executed. Backups require an application envelope before upload; SSE-S3 alone does not make them confidential from authorized readers.
