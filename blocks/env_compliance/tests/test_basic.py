"""
Tests for Environmental Compliance (blocks/env_compliance)
"""
import unittest
from pathlib import Path
import sys

# Add Block root to path to import internal modules
BLOCK_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(BLOCK_ROOT))

class TestEnvCompliance(unittest.TestCase):
    def test_rules_file_exists(self):
        rules_path = BLOCK_ROOT / "rules.json"
        self.assertTrue(rules_path.exists(), "Rules file must exist")

    def test_validator_importable(self):
        try:
            import validate_environment
            self.assertIsNotNone(validate_environment.__file__)
        except ImportError:
            self.fail("Could not import validator")

if __name__ == "__main__":
    unittest.main()
