
import unittest
from titan_kernel import AuthorityLevel, ActionType, Requestor, Decree, ExecutionPermitGateway

class TestTitanAuthority(unittest.TestCase):
    
    def setUp(self):
        self.gateway = ExecutionPermitGateway()
        self.l0_user = Requestor("Owner", AuthorityLevel.L0_SUPREME)
        self.l2_user = Requestor("Manager", AuthorityLevel.L2_MANAGERIAL)
        self.l3_bot = Requestor("PaymentBot", AuthorityLevel.L3_OPERATIONAL)
        self.l4_bot = Requestor("ViewBot", AuthorityLevel.L4_TASK)

    def test_l4_blocked_write(self):
        # L4 cannot Write DB
        d = Decree("Update User", ActionType.WRITE_DB, self.l4_bot)
        permit = self.gateway.request_permit(d)
        self.assertIsNone(permit, "L4 should be blocked from Writing DB")

    def test_l4_blocked_spend(self):
        # L4 cannot Spend
        d = Decree("Buy Coffee", ActionType.SPEND_MONEY, self.l4_bot, 5.0)
        permit = self.gateway.request_permit(d)
        self.assertIsNone(permit, "L4 should be blocked from Spending")

    def test_l3_spend_under_limit(self):
        # L3 can spend < $50 without trigger (assuming Board approves low risk)
        d = Decree("Server Cost", ActionType.SPEND_MONEY, self.l3_bot, 40.0)
        permit = self.gateway.request_permit(d)
        self.assertIsNotNone(permit)
        self.assertTrue(permit.is_valid)

    def test_l0_override(self):
        # L0 can do anything
        d = Decree("Destroy World", ActionType.WRITE_DB, self.l0_user)
        permit = self.gateway.request_permit(d)
        self.assertIsNotNone(permit)
        self.assertTrue(permit.is_valid)

if __name__ == '__main__':
    unittest.main()
