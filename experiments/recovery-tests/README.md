# Recovery experiments

See `../tests/test_recovery.py` and `../../architecture/recovery.md`. Restore consumes an independently selected latest checkpoint and two declared approval identities. Tests exercise stale/current snapshots, epoch changes, consumed requests, missing/forged checkpoint, signer loss and the deliberate joint-rollback counterexample. These are local state-model experiments; no S3 or live signer restore occurs.
