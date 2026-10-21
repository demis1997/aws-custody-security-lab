# Architecture and implementation boundary

The lab asks whether signing and transaction authorization survive the compromise of a host, account administrator, deployment pipeline, or recovery authority. It models 2-of-3 signing participants, not a new threshold cryptographic protocol. [Quorum Custody](https://github.com/demis1997/quorum-custody/tree/691e253ccdc2756afe215a23384eb72e2d4fde3c) supplies the implementation reference; it is neither vendored nor deployed by this repository.

![AWS institutional custody architecture](diagrams/aws-custody.svg)

## Domain inventory

| Domain | Synthetic account | Authority and deployment root |
| --- | --- | --- |
| Signer A | 111111111111 | One signing participant; independent admin, provisioner and key admin; `lab` root |
| Signer B | 222222222222 | Second independent participant; `lab` root with B credentials/state |
| Signer C | 333333333333 | Third independent participant; `lab` root with C credentials/state |
| Coordinator | 444444444444 | Request lifecycle and network submission; no signer backup permission; `lab` root |
| Authorization | 555555555555 | Intended independent approval/policy authority; host shell only; application/key integration deferred |
| Security | 666666666666 | Audit evidence bucket and separately governed checkpoint publication identity; `security` root |
| Recovery | 777777777777 | Retained backups, checkpoint objects and reviewed read access; `recovery` root |

All account IDs are examples, not discovered credentials. Accounts and bootstrap roles must already exist. The Terraform does not create an organization or accounts. One root deploys into one expected account using that domain's independently governed credentials. It does not assume a single principal can provision every signer. Independent state access and release approval are operational prerequisites, not something these files can prove.

## What the infrastructure actually does

The workload root composes a private VPC/subnet/route table, empty default security group, explicit mTLS peer rules, restricted API endpoints, an IMDSv2-only encrypted EC2 host, runtime identity, an operator trust shell without session permissions, and account-level logging/GuardDuty configuration. Signers additionally receive a context-bound KMS envelope key and write-only backup prefix. Peer request/accept resources support a staged, two-party-reviewed VPC peering setup; no peer routes are open by default. There is no Internet gateway, NAT gateway, SSH key or public workload IP.

The EC2 hosts deliberately contain **no installed custody software**, approval service, CA, database, signer share, secret or private key. No remote TLS, protocol, transaction, logging-agent or restore integration has been executed. A future application integration must use reviewed, per-domain artifacts and the upstream native adapter; empty hosts are not a functioning custody service.

Audit/recovery roots create private, versioned, SSE-S3 encrypted evidence buckets with 30-day COMPLIANCE retention, explicit bucket policies and Terraform destruction protection. S3 retention protects versions; it does not identify which version represents current authorization state. A compromised recovery operator can still choose an old object unless an independent trusted-latest anchor is checked.

The organization root creates an optional SCP and OU attachment in the management account. It does not provision the OU or organization, enroll GuardDuty members, create centralized Config rules, or constrain the management account itself.

## Network and chain paths

Peer application traffic is TCP 8443 with mTLS required by the proposed application design. Security groups and routes enforce reachability; they do not implement certificate authentication. Each peer request must be accepted in the other domain and given the reverse route. The default examples have no peer communication.

SSM/SSM Messages, CloudWatch Logs and KMS use private interface endpoints. Signer backups use the S3 gateway endpoint and an exact object prefix. KMS access does not imply access to another domain's key. The coordinator may be configured for HTTPS to explicit private RPC proxy CIDRs; the proxy and its upstream Ethereum connection are not supplied. There is no unrestricted Internet RPC route.

See [trust boundaries](trust-boundaries.md), [IAM](iam-design.md), [key protection](key-protection.md), [recovery](recovery.md), [service decisions](service-decisions.md), and [deployment prerequisites](../terraform/README.md).
