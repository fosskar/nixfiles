"""Pure-logic tests; run at package build time (checkPhase), no network."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path
from unittest import mock

import changelog

from packages import Package

# `import __main__` would resolve to the test runner itself.
_spec = importlib.util.spec_from_file_location(
    "updater_main", Path(__file__).with_name("__main__.py")
)
_main = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_main)
commit_message = _main.commit_message
group_packages = _main.group_packages


def pkg(name: str) -> Package:
    return Package(name, "nix-update", Path(f"packages/{name}"))


class TestGrouping(unittest.TestCase):
    def test_shared_prefix_grouped(self):
        groups = group_packages([pkg("netbird-client"), pkg("netbird-server")])
        self.assertEqual(list(groups), ["netbird"])
        self.assertEqual(len(groups["netbird"]), 2)

    def test_singleton_keeps_full_name(self):
        groups = group_packages([pkg("garage-ui"), pkg("voquill")])
        self.assertEqual(list(groups), ["garage-ui", "voquill"])


class TestCommitMessage(unittest.TestCase):
    def test_single(self):
        self.assertEqual(
            commit_message("voquill", ["voquill: 1 -> 2"]), "voquill: 1 -> 2"
        )

    def test_group_gets_header(self):
        msg = commit_message("netbird", ["a: 1 -> 2", "b: 1 -> 2"])
        self.assertEqual(msg.splitlines()[0], "update netbird")
        self.assertIn("a: 1 -> 2", msg)
        self.assertIn("b: 1 -> 2", msg)


class TestChangelog(unittest.TestCase):
    COMPARE = "Diff: https://github.com/o/r/compare/v1.0.0...v1.1.0"

    def test_dedupe_same_release(self):
        msg = f"{self.COMPARE}\n\n{self.COMPARE}"
        with mock.patch.object(changelog, "_release_body", return_value="NOTES"):
            out = changelog.enrich(msg)
        self.assertEqual(out.count("<details>"), 1)

    def test_truncation(self):
        with mock.patch.object(changelog, "_release_body", return_value="x" * 5000):
            out = changelog.enrich(self.COMPARE, max_len=100)
        self.assertIn("(truncated)", out)

    def test_no_notes_no_details(self):
        with mock.patch.object(changelog, "_release_body", return_value=None):
            out = changelog.enrich(self.COMPARE)
        self.assertNotIn("<details>", out)


if __name__ == "__main__":
    unittest.main()
