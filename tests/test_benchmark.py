"""Benchmark runner contracts; these do not assert compiler performance."""
import subprocess
import sys
import unittest

from benchmark import compile_once


class BenchmarkTests(unittest.TestCase):
    def test_success(self):
        self.assertGreater(compile_once([sys.executable, "-c", "pass"], 5), 0)

    def test_failure_preserves_diagnostic(self):
        with self.assertRaises(subprocess.CalledProcessError) as failure:
            compile_once([sys.executable, "-c", "import sys; sys.exit('fixture failed')"], 5)
        self.assertIn("fixture failed", failure.exception.stderr)

    def test_timeout(self):
        with self.assertRaises(subprocess.TimeoutExpired):
            compile_once([sys.executable, "-c", "import time; time.sleep(30)"], 0.1)


if __name__ == "__main__":
    unittest.main()
