# Trust boundaries

![Administrative separation](diagrams/iam-trust.svg)

A signer domain comprises host execution, instance role, share storage, KMS policy administration, image/release authority and its state. A compromised host that can decrypt a share belongs inside that signer boundary. Encrypting the disk does not remove the live process from the threat model.

Three accounts are independent only relative to specified administrators. A common account root recovery email, SSO superadministrator, CI deploy role, signing image publisher, certificate issuer or recovery operator can reconnect them. The simulation deliberately includes a shared deployment principal controlling all three hosts and demonstrates quorum compromise.

Terraform state is a control plane asset: a principal who can alter plans, state, module source or approved images can replace controls. Never share an administrative state backend, workstation credential or automatic deployment job across the three signing domains and then describe the result as independent. This repository's CI has no AWS credential or deployment permission.

Organizations management can remove SCPs. That alone does not automatically grant access to every member workload. If member accounts retain a management-trusted administrative role, the same compromise may reach all signers. Both cases are modeled separately. See [AWS SCP semantics](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html).

Authorization is another boundary. Compromising enough approval authorities can produce cryptographically valid approvals for a transaction that no legitimate human intended. Honest signers can enforce recipient/budget/epoch rules but cannot reconstruct absent human intent. Keep policy administration and the two approval devices independent; the authorization host is not proof of that independence.

An independently administered recovery store is necessary but insufficient. The current checkpoint authority, its key, the mechanism for selecting the latest record, and the restore approval quorum must all resist the declared attacker. Joint rollback of state and that trusted-latest anchor defeats the modeled protection.

No AWS control plane, cloud provider compromise, host attestation, live network isolation, or independent human administration was tested. These assumptions are explicitly carried into the threat model and findings.
