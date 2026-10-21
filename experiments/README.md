# Local experiments

Run from the repository root:

```sh
PYTHONPATH=experiments python3 -m unittest discover -s experiments/tests -v
python3 experiments/run.py
```

Set `PYTHONPATH=experiments` for direct unittest discovery, or use `bash scripts/validate.sh` which sets it for you. No third-party Python packages, AWS credentials, wallet credentials, or funds are required. Results go to ignored `results/local/`; publication evidence is retained in `results/published/`.

`lab_model.py` is an executable model of authority, approval binding, budget state, and recovery. Its HMACs detect synthetic fixture tampering; they are not asymmetric approval signatures or MPC. Signer control and IAM edges are declared attacker capabilities. The tests are architecture assertions, not AWS penetration tests, IAM policy simulator output, native cb-mpc execution, or a production recovery implementation.

`test_compromise.py` checks independent and shared administration, authorization compromise, quorum control, approval tampering, expiry, chain binding, and consistent versus divergent budgets. `test_recovery.py` covers stale backup/policy, consumed approval replay, signer loss, trusted checkpoint loss, recovery approval quorum, valid restoration, forgery, and joint state/anchor rollback. The last case intentionally demonstrates a failure of the trust assumption.

The actual Terraform configuration also has `terraform test` plan assertions using mocked AWS providers. Those tests evaluate generated policy JSON and resource configuration, not remote AWS enforcement. See VALIDATION_REPORT.md for commands, outcomes, and what was not executed.
