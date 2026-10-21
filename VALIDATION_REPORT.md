# Validation report

Executed **21 October 2026** on macOS ARM64. Terraform **1.9.8**, AWS provider **5.100.0**, Python **3.15.0**. The checked source includes seven modules and four independently operated deployment roots. Hosted CI uses Python 3.11 on Ubuntu; its workflow result is a separate execution record.

## Executed checks

| Check | Actual result | Evidence and boundary |
| --- | --- | --- |
| Terraform formatting | Passed | `terraform fmt -check -recursive terraform` |
| Provider/module initialization | Passed for all four roots | Backend disabled; exact provider and committed lockfiles; no AWS authentication. |
| Terraform configuration validation | Passed for all four roots | Actual provider schema validation. |
| Workload policy plans | **9 passed, 0 failed** | Private host, IMDSv2, encryption, KMS context, exact/MFA operator trust, signer backup scope, coordinator separation and negative inputs. |
| Audit policy plans | **3 passed, 0 failed** | Bounded CloudTrail delivery, explicit deployment guard and locked/private/versioned evidence. |
| Recovery policy plans | **3 passed, 0 failed** | Separate backup/checkpoint/reader capability, deployment guard and evidence retention contract. |
| Organization guardrail plans | **2 passed, 0 failed** | Mocked configuration plan and deployment acknowledgement rejection. |
| Python security and recovery tests | **29 passed, 0 failures** | Local synthetic HMAC/state/authority models; no AWS or MPC execution. |
| Scenario records | **15 expected/actual outcomes matched** | Nine authority-graph and six restore scenarios. |
| Defense-removal controls | **2 mutations detected** | Tests failed as expected when one-share quorum or stale-anchor acceptance was introduced in temporary copies. |
| SVG generation | Passed; four exports reviewed | Deterministic diagram source, XML parsing and visual review; no remote assets or scripts. |
| Local links / publication safety | Passed | `scripts/check-publication.py`; credential-type/pattern, private-host and mocked-test guards. |
| Workflow YAML | Parsed successfully | Pinned actions, read-only permissions, no AWS credentials and no apply step. |

A final workload-only follow-up added and passed two peering-route checks: rejecting an unapproved broad route and planning explicit request/accept routes. All nine workload runs were re-executed after that change; the other validated roots were unchanged.

Run `bash scripts/validate.sh` to reproduce. Raw original records and logs are in [results/published](results/published/); their hashes are in [SHA256SUMS.json](results/published/SHA256SUMS.json). New runs write to ignored `results/local/` and do not replace those records. Expected defense failures and unsafe-model counterexamples are labeled explicitly.

The two mutation checks establish that selected tests detect removed defenses. They do not prove the model or infrastructure secure. `terraform test` uses mocked AWS providers and plan commands only: it validates generated configuration and policy intent, not remote AWS enforcement. No live resources were created or charged by these checks.

## Secret review

The intended publication tree is scanned with Gitleaks **8.30.1**, obtained from its official release and checked against the publisher's SHA-256 list, plus high-confidence credential-pattern checks in the local validator. The final intended-file scan reported **no leaks found**. An initial finding was the SHA-256 hash of the scan log itself, verified against that file; renaming the evidence record to `gitleaks.log` removed the filename-triggered false positive without disabling a detection rule. Generated dependencies, `.terraform`, state, tfvars, environment files, private keys and local results are excluded. Keys are generated only in memory for local fixtures; no keys, credentials, AWS account discovery or wallet funds are used.

## Not Executed

Real AWS plan/apply, account/bootstrap creation, AWS authentication, IAM Access Analyzer or IAM Policy Simulator, live AssumeRole escalation tests, packet/mTLS tests, CloudTrail delivery/digest verification, S3 Object Lock delete attempts, Config/GuardDuty findings, AWS recovery/failover, cost/performance measurements, native cb-mpc DKG/signing, Ethereum submission, CloudHSM/Nitro tests and post quantum contract integration.

Checkov, Trivy and TFLint were not run. The implemented policy-testing equivalent is seventeen Terraform plan runs against actual resource/policy definitions, plus Python model and publication checks. There is no compliance certification, penetration-test claim or production deployment.

## Deployment boundary

Examples contain synthetic IDs and placeholders. The acknowledgement variable defaults false, no real deployment command runs in CI, and the validation runner clears AWS/TF_VAR child environment inputs and disables AWS metadata/shared credential files. Account/state ownership, independent administration, software release, CA, live checkpoint selection, two-person restore enforcement, database and private RPC integration require further review and separate deployment/cost approval. See [limitations](research/limitations.md) and [deployment prerequisites](terraform/README.md).
