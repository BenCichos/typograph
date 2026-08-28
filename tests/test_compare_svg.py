"""Contracts for the documentation SVG staleness helper (stdlib only)."""

import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("compare-svg.py")
SPEC = importlib.util.spec_from_file_location("compare_svg", SCRIPT)
compare_svg = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(compare_svg)


class CompareSvgTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="typograph-svg-test-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)

    def fixture(self, name, text):
        path = self.root / name
        path.write_text(text, encoding="utf-8")
        return path

    def run_compare(self, *args):
        return subprocess.run(
            [sys.executable, str(SCRIPT), *map(str, args)],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_identical_files_and_unicode(self):
        value = '<svg aria-label="α → β"><path d="M 1.234 -5.678"/></svg>'
        a = self.fixture("a.svg", value)
        b = self.fixture("b.svg", value)
        self.assertEqual(self.run_compare(a, b).returncode, 0)

    def test_small_jitter_within_one_rounding_bucket(self):
        a = self.fixture("a.svg", '<svg width="10.231"/>')
        b = self.fixture("b.svg", '<svg width="10.234"/>')
        self.assertEqual(self.run_compare(a, b).returncode, 0)

    def test_geometry_change_is_detected(self):
        a = self.fixture("a.svg", '<path d="M 1.23 -2.50"/>')
        b = self.fixture("b.svg", '<path d="M 1.43 -2.50"/>')
        self.assertEqual(self.run_compare(a, b).returncode, 1)

    def test_paint_change_is_detected(self):
        a = self.fixture("a.svg", '<path fill="#ff0000"/>')
        b = self.fixture("b.svg", '<path fill="#0000ff"/>')
        self.assertEqual(self.run_compare(a, b).returncode, 1)

    def test_structure_change_is_detected(self):
        a = self.fixture("a.svg", '<svg><path d="M 0 0"/></svg>')
        b = self.fixture("b.svg", '<svg><path d="M 0 0"/><circle r="1"/></svg>')
        self.assertEqual(self.run_compare(a, b).returncode, 1)

    def test_signed_decimal_rounding(self):
        path = self.fixture("a.svg", '<path d="M -1.234 2.346"/>')
        self.assertEqual(compare_svg.normalize(path), '<path d="M -1.23 2.35"/>')

    def test_rounding_is_not_an_absolute_difference_tolerance(self):
        a = self.fixture("a.svg", '<svg width="1.2349"/>')
        b = self.fixture("b.svg", '<svg width="1.2351"/>')
        self.assertEqual(self.run_compare(a, b).returncode, 1)

    def test_usage_exit_status(self):
        result = self.run_compare()
        self.assertEqual(result.returncode, 2)
        self.assertIn("usage: compare-svg.py", result.stderr)

    def test_missing_file_never_passes(self):
        a = self.fixture("a.svg", "<svg/>")
        self.assertNotEqual(self.run_compare(a, self.root / "missing.svg").returncode, 0)


if __name__ == "__main__":
    unittest.main()
