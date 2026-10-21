"""Executable authority and recovery model. No AWS calls or threshold cryptography.

HMACs make fixture tampering observable; they do not implement asymmetric
approval signatures, a hardware boundary, Ethereum signing, or an MPC protocol.
"""
from dataclasses import dataclass, field, asdict
import hashlib, hmac, json, secrets


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":")).encode()


@dataclass
class State:
    epoch: int = 1
    next_nonce: int = 0
    spent: int = 0
    consumed: list = field(default_factory=list)


@dataclass(frozen=True)
class Intent:
    request_id: str
    nonce: int
    recipient: str
    amount: int
    epoch: int = 1
    expires_at: int = 200
    chain_id: int = 31337
    wallet: str = "synthetic-custody"


class CustodyModel:
    def __init__(self):
        self.state = State()
        self.approval_keys = {p: secrets.token_bytes(32) for p in ("approver-1", "approver-2")}
        self.checkpoint_key = secrets.token_bytes(32)
        self.signers = {"a", "b", "c"}
        self.allowed_recipients = {"approved-beneficiary"}

    def approve(self, intent, principals=("approver-1", "approver-2")):
        message = b"custody-lab/approval/v1\0" + canonical(asdict(intent))
        return {p: hmac.digest(self.approval_keys[p], message, "sha256").hex() for p in principals}

    def execute(self, intent, approvals, available=None, now=100):
        if intent.chain_id != 31337 or intent.wallet != "synthetic-custody":
            raise PermissionError("wrong-domain")
        if intent.epoch != self.state.epoch:
            raise PermissionError("stale-policy")
        if intent.expires_at <= now:
            raise PermissionError("expired-approval")
        if intent.nonce != self.state.next_nonce or intent.request_id in self.state.consumed:
            raise PermissionError("replay-or-nonce")
        if intent.recipient not in self.allowed_recipients or not 0 < intent.amount <= 80:
            raise PermissionError("transaction-policy")
        if self.state.spent + intent.amount > 100:
            raise PermissionError("aggregate-budget")
        expected = self.approve(intent)
        if len([p for p, signature in approvals.items() if p in expected and hmac.compare_digest(signature, expected[p])]) < 2:
            raise PermissionError("insufficient-approvals")
        live = self.signers if available is None else self.signers.intersection(available)
        if len(live) < 2:
            raise PermissionError("insufficient-signers")
        self.state.next_nonce += 1
        self.state.spent += intent.amount
        self.state.consumed.append(intent.request_id)
        # Portable-authority marker only; not an Ethereum signature.
        return {"accepted": True, "intent_digest": hashlib.sha256(canonical(asdict(intent))).hexdigest()}

    def checkpoint(self):
        state = asdict(self.state)
        digest = hashlib.sha256(canonical(state)).hexdigest()
        payload = {"generation": self.state.next_nonce, "epoch": self.state.epoch, "digest": digest}
        attestation = hmac.digest(self.checkpoint_key, b"custody-lab/checkpoint/v1\0" + canonical(payload), "sha256").hex()
        return state, {**payload, "attestation": attestation}

    def restore(self, snapshot, checkpoint, trusted_latest, approvals=frozenset({"recovery-1", "recovery-2"})):
        if not {"recovery-1", "recovery-2"}.issubset(approvals):
            raise PermissionError("recovery-quorum")
        if checkpoint is None or trusted_latest is None:
            raise PermissionError("missing-checkpoint")
        payload = {k: checkpoint[k] for k in ("generation", "epoch", "digest")}
        mac = hmac.digest(self.checkpoint_key, b"custody-lab/checkpoint/v1\0" + canonical(payload), "sha256").hex()
        if not hmac.compare_digest(mac, checkpoint["attestation"]):
            raise PermissionError("forged-checkpoint")
        if checkpoint != trusted_latest:
            raise PermissionError("stale-checkpoint")
        if hashlib.sha256(canonical(snapshot)).hexdigest() != checkpoint["digest"]:
            raise PermissionError("backup-integrity")
        self.state = State(**json.loads(canonical(snapshot)))


# Edges are declared administrative capabilities, not AWS IAM evaluation results.
AUTHORITY = {
    "host-a": {"signer-a"}, "host-b": {"signer-b"}, "host-c": {"signer-c"},
    "deploy-a": {"host-a"}, "deploy-b": {"host-b"}, "deploy-c": {"host-c"},
    "admin-a": {"deploy-a", "key-policy-a"}, "admin-b": {"deploy-b", "key-policy-b"},
    "admin-c": {"deploy-c", "key-policy-c"},
    "key-policy-a": {"share-a"}, "key-policy-b": {"share-b"}, "key-policy-c": {"share-c"},
    "coordinator": {"retain-portable-signed-bytes"},
    "authorization-service": {"approver-1", "approver-2"},
    "shared-deployer": {"deploy-a", "deploy-b", "deploy-c"},
    "recovery-operator": {"backup-read"},
    "org-management": {"remove-scp"},
    "org-with-member-admin-trust": {"org-management", "admin-a", "admin-b", "admin-c"},
}


def closure(principals, graph=AUTHORITY):
    reached = set(principals)
    pending = list(principals)
    while pending:
        for child in graph.get(pending.pop(), set()) - reached:
            reached.add(child)
            pending.append(child)
    return reached


def controls_quorum(principals):
    capabilities = closure(principals)
    return len([s for s in "abc" if f"signer-{s}" in capabilities or f"share-{s}" in capabilities]) >= 2
