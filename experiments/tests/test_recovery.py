import unittest
from copy import deepcopy
from dataclasses import replace
from lab_model import CustodyModel, Intent


class RecoveryTests(unittest.TestCase):
    def setUp(self):
        self.model = CustodyModel()
        self.intent = Intent("request-1", 0, "approved-beneficiary", 30)
        self.old_state, self.old_checkpoint = self.model.checkpoint()
        self.model.execute(self.intent, self.model.approve(self.intent))
        self.latest_state, self.latest_checkpoint = self.model.checkpoint()

    def test_stale_backup_rejected_against_current_checkpoint(self):
        with self.assertRaisesRegex(PermissionError, "backup-integrity"):
            self.model.restore(self.old_state, self.latest_checkpoint, self.latest_checkpoint)

    def test_old_matching_checkpoint_rejected_by_independent_latest_anchor(self):
        with self.assertRaisesRegex(PermissionError, "stale-checkpoint"):
            self.model.restore(self.old_state, self.old_checkpoint, self.latest_checkpoint)

    def test_replay_consumed_approval_rejected_after_valid_restore(self):
        self.model.restore(self.latest_state, self.latest_checkpoint, self.latest_checkpoint)
        with self.assertRaisesRegex(PermissionError, "replay-or-nonce"):
            self.model.execute(self.intent, self.model.approve(self.intent))

    def test_old_authorization_policy_rejected(self):
        self.model.state.epoch = 2
        next_intent = replace(self.intent, request_id="new", nonce=1)
        with self.assertRaisesRegex(PermissionError, "stale-policy"):
            self.model.execute(next_intent, self.model.approve(next_intent))

    def test_one_signer_lost_surviving_quorum_remains_available(self):
        next_intent = replace(self.intent, request_id="new", nonce=1)
        self.assertTrue(self.model.execute(next_intent, self.model.approve(next_intent), {"b", "c"})["accepted"])

    def test_two_signers_lost_fail_closed(self):
        next_intent = replace(self.intent, request_id="new", nonce=1)
        with self.assertRaisesRegex(PermissionError, "insufficient-signers"):
            self.model.execute(next_intent, self.model.approve(next_intent), {"c"})

    def test_lost_checkpoint_fails_closed(self):
        with self.assertRaisesRegex(PermissionError, "missing-checkpoint"):
            self.model.restore(self.latest_state, None, None)

    def test_one_recovery_operator_cannot_restore(self):
        with self.assertRaisesRegex(PermissionError, "recovery-quorum"):
            self.model.restore(self.latest_state, self.latest_checkpoint, self.latest_checkpoint, {"recovery-1"})

    def test_rolling_back_both_state_and_trusted_anchor_reenables_replay(self):
        # Explicit counterexample: trusted-latest independence has been lost.
        self.model.restore(self.old_state, self.old_checkpoint, self.old_checkpoint)
        self.assertTrue(self.model.execute(self.intent, self.model.approve(self.intent))["accepted"])

    def test_forged_checkpoint_cannot_become_trusted_merely_by_relabeling(self):
        forged = deepcopy(self.latest_checkpoint)
        forged["digest"] = "0" * 64
        with self.assertRaisesRegex(PermissionError, "forged-checkpoint"):
            self.model.restore(self.latest_state, forged, forged)

    def test_quorum_survives_valid_restore_without_resetting_spend(self):
        self.model.restore(self.latest_state, self.latest_checkpoint, self.latest_checkpoint)
        self.assertEqual(self.model.state.spent, 30)
        self.assertEqual(self.model.state.next_nonce, 1)

    def test_old_policy_snapshot_rejected_after_epoch_checkpoint_advances(self):
        self.model.state.epoch = 2
        state, current = self.model.checkpoint()
        with self.assertRaisesRegex(PermissionError, "stale-checkpoint"):
            self.model.restore(self.old_state, self.old_checkpoint, current)
