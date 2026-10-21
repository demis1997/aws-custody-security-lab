# Assets and invariants

Protect asset-movement authority, approval/policy keys, threshold shares, live signer memory, nonce and spending history, consumed approvals, recovery checkpoints, encrypted backup/decryption capability, deployment artifacts, Terraform state, CA identities, account bootstrap/recovery paths, and audit evidence.

Invariants: one domain compromise must not alone reach a signing quorum under the independent-control model; honest signers require bound current approvals and policy; every accepted request consumes one nonce and budget reservation; restoration must preserve current policy and consumed history; missing recovery evidence must fail closed; audit publication must not confer deletion or signing authority. Two malicious signing domains are sufficient to defeat threshold authorization in this model.

Availability is separate: any two available honest participants can proceed with valid evidence, while one participant alone cannot. This is a model property, not measured cb-mpc liveness or a Byzantine consensus proof. Public-chain validity after signature issuance is not revocable by a private application flag.
