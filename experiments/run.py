#!/usr/bin/env python3
"""Emit reproducible expected/actual model outcomes; no live service operations."""
from pathlib import Path
from datetime import datetime, timezone
import argparse, json, platform
from lab_model import CustodyModel, Intent, controls_quorum, closure


def scenarios():
    rows = []
    for name,principals,expected in [
        ("compromised-signer-a", {"host-a"}, False),
        ("two-compromised-signers", {"host-a","host-b"}, True),
        ("compromised-coordinator", {"coordinator"}, False),
        ("stolen-domain-a-role", {"deploy-a"}, False),
        ("shared-ci-deployment-authority", {"shared-deployer"}, True),
        ("malicious-domain-a-admin", {"admin-a"}, False),
        ("compromised-kms-policy-a", {"key-policy-a"}, False),
        ("organizations-without-member-admin-trust", {"org-management"}, False),
        ("organizations-with-member-admin-trust", {"org-with-member-admin-trust"}, True),
    ]:
        actual=controls_quorum(principals)
        assert actual==expected
        rows.append({"scenario":name,"expected_quorum_control":expected,"actual_quorum_control":actual,"capabilities":sorted(closure(principals)),"scope":"declared authority graph; no AWS IAM or MPC execution"})
    m=CustodyModel();intent=Intent("synthetic-1",0,"approved-beneficiary",30)
    old,oldcp=m.checkpoint();m.execute(intent,m.approve(intent));latest,cp=m.checkpoint()
    for name,snapshot,checkpoint,anchor,approvers,expected in [
        ("stale-signer-backup",old,cp,cp,{"recovery-1","recovery-2"},"backup-integrity"),
        ("stale-checkpoint",old,oldcp,cp,{"recovery-1","recovery-2"},"stale-checkpoint"),
        ("lost-checkpoint",latest,None,None,{"recovery-1","recovery-2"},"missing-checkpoint"),
        ("compromised-recovery-operator",latest,cp,cp,{"recovery-1"},"recovery-quorum"),
        ("current-state-and-anchor",latest,cp,cp,{"recovery-1","recovery-2"},"accepted"),
        ("state-plus-anchor-rollback",old,oldcp,oldcp,{"recovery-1","recovery-2"},"accepted"),
    ]:
        try:m.restore(snapshot,checkpoint,anchor,approvers);actual="accepted"
        except PermissionError as e:actual=str(e)
        assert actual==expected
        rows.append({"scenario":name,"expected":expected,"actual":actual,"scope":"local synthetic recovery state and HMAC fixture; no AWS restore"})
    return rows


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument('--output',default='results/local/scenarios.json');args=p.parse_args()
    result={"executed_at":datetime.now(timezone.utc).isoformat(),"python":platform.python_version(),"scope":"Architectural models only; no live AWS, MPC, HSM, or Ethereum signing.","records":scenarios()}
    out=Path(args.output);out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(result,indent=2)+'\n')
    print(f'{len(result["records"])} scenario outcomes matched expected behavior; records: {out}')
