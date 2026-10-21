import unittest
from dataclasses import replace
from lab_model import CustodyModel, Intent, closure, controls_quorum


class CompromiseTests(unittest.TestCase):
    def setUp(self):
        self.model = CustodyModel()
        self.intent = Intent("request-1", 0, "approved-beneficiary", 30)

    def test_single_signer_cannot_control_quorum(self):
        self.assertFalse(controls_quorum({"host-a"}))

    def test_two_compromised_signers_control_direct_authority(self):
        self.assertTrue(controls_quorum({"host-a", "host-b"}))

    def test_coordinator_cannot_create_approvals(self):
        with self.assertRaisesRegex(PermissionError, "insufficient-approvals"):
            self.model.execute(self.intent, {})
        self.assertFalse(controls_quorum({"coordinator"}))

    def test_shared_deployment_collapses_account_separation(self):
        self.assertTrue(controls_quorum({"shared-deployer"}))

    def test_one_domain_admin_stays_in_one_domain(self):
        self.assertFalse(controls_quorum({"admin-a"}))
        self.assertNotIn("host-b", closure({"admin-a"}))

    def test_authorizer_compromise_can_permit_business_fraud_within_policy(self):
        # Both approval keys compromised is sufficient to misrepresent human intent.
        approvals = self.model.approve(self.intent)
        self.assertTrue(self.model.execute(self.intent, approvals)["accepted"])

    def test_authorizer_cannot_override_signer_recipient_policy(self):
        bad = replace(self.intent, recipient="attacker")
        with self.assertRaisesRegex(PermissionError, "transaction-policy"):
            self.model.execute(bad, self.model.approve(bad))

    def test_stolen_one_domain_role_cannot_assume_another_in_model(self):
        self.assertNotIn("deploy-b", closure({"deploy-a"}))

    def test_key_policy_compromise_is_one_share_not_threshold_hardware(self):
        self.assertFalse(controls_quorum({"key-policy-a"}))
        self.assertTrue(controls_quorum({"key-policy-a", "key-policy-b"}))

    def test_org_management_without_member_trust_only_removes_guardrails(self):
        self.assertFalse(controls_quorum({"org-management"}))
        self.assertIn("remove-scp", closure({"org-management"}))

    def test_org_management_with_member_admin_trust_controls_quorum(self):
        self.assertTrue(controls_quorum({"org-with-member-admin-trust"}))

    def test_tampering_approved_transaction_is_rejected(self):
        approvals = self.model.approve(self.intent)
        with self.assertRaisesRegex(PermissionError, "insufficient-approvals"):
            self.model.execute(replace(self.intent, amount=31), approvals)

    def test_one_approver_is_not_sufficient(self):
        with self.assertRaisesRegex(PermissionError, "insufficient-approvals"):
            self.model.execute(self.intent, self.model.approve(self.intent, ("approver-1",)))

    def test_expired_approval_rejected_before_new_issuance(self):
        with self.assertRaisesRegex(PermissionError, "expired-approval"):
            self.model.execute(self.intent, self.model.approve(self.intent), now=201)

    def test_wrong_chain_domain_rejected(self):
        bad = replace(self.intent, chain_id=1)
        with self.assertRaisesRegex(PermissionError, "wrong-domain"):
            self.model.execute(bad, self.model.approve(bad))

    def test_consistent_budget_rejects_second_sixty_unit_intent(self):
        first = replace(self.intent, amount=60)
        self.model.execute(first, self.model.approve(first))
        second = Intent("second", 1, "approved-beneficiary", 60)
        with self.assertRaisesRegex(PermissionError, "aggregate-budget"):
            self.model.execute(second, self.model.approve(second))

    def test_divergent_ledgers_can_each_accept_sixty_units(self):
        first = replace(self.intent, amount=60)
        other = CustodyModel()
        self.model.execute(first, self.model.approve(first))
        second = Intent("second", 0, "approved-beneficiary", 60)
        other.execute(second, other.approve(second))
        self.assertEqual(self.model.state.spent + other.state.spent, 120)
