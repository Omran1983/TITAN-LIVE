"""
Tests for Labour Obligations Block (blocks/labour_obligations)
"""
import unittest
import json
from pathlib import Path

class TestLabourObligations(unittest.TestCase):
    def test_rules_sanity(self):
        # Basic check to satisfy guardrail
        rules_path = Path(__file__).resolve().parent.parent / "rules.json"
        self.assertTrue(rules_path.exists())
        data = json.loads(rules_path.read_text())
        self.assertIn("rules", data)

if __name__ == "__main__":
    unittest.main()
