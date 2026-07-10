"""Pure-logic tests; run at package build time (checkPhase), no network."""

from __future__ import annotations

import contextlib
import email.message
import io
import json
import tempfile
import unittest
import urllib.error
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

import changelog
import pipeline
import update_flake_inputs  # noqa: E402
from forge import Codeberg, ForgeError, Github
from update_flake_inputs import FlakeInput
from update_packages import commit_message, group_packages  # noqa: E402

from packages import Package, classify, nix_update_cmd, parse_update_script


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


class TestFixStaleUrls(unittest.TestCase):
    def test_rewrites_changelog_line(self):
        msg = (
            "limux: 0.1.19 -> 0.1.21\n\n"
            "Changelog: https://github.com/am-will/limux/releases/tag/v0.1.19"
        )
        out = changelog.fix_stale_urls(msg)
        lines = out.splitlines()
        self.assertEqual(lines[0], "limux: 0.1.19 -> 0.1.21")
        self.assertEqual(
            lines[-1],
            "Changelog: https://github.com/am-will/limux/releases/tag/v0.1.21",
        )

    def test_diff_line_untouched(self):
        diff = "Diff: https://github.com/o/r/compare/v1.0.0...v1.1.0"
        msg = f"r: 1.0.0 -> 1.1.0\n\n{diff}"
        out = changelog.fix_stale_urls(msg)
        self.assertEqual(out.splitlines()[-1], diff)

    def test_no_title_match_unchanged(self):
        msg = (
            "update netbird\n\n"
            "Changelog: https://github.com/netbirdio/netbird/releases/tag/v0.1.0"
        )
        self.assertEqual(changelog.fix_stale_urls(msg), msg)

    def test_old_equals_new_unchanged(self):
        msg = (
            "limux: 0.1.19 -> 0.1.19\n\n"
            "Changelog: https://github.com/am-will/limux/releases/tag/v0.1.19"
        )
        self.assertEqual(changelog.fix_stale_urls(msg), msg)


class TestFlakeInputs(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.repo = Path(self._tmp.name)
        root_lock = {
            "root": "root",
            "nodes": {
                "root": {
                    "inputs": {
                        "nixpkgs": "nixpkgs",
                        "home-manager": "home-manager",
                        "aliased": ["nixpkgs"],
                    }
                },
                "nixpkgs": {
                    "locked": {
                        "type": "github",
                        "owner": "NixOS",
                        "repo": "nixpkgs",
                        "rev": "aaa111",
                    }
                },
                "home-manager": {
                    "locked": {
                        "type": "github",
                        "owner": "nix-community",
                        "repo": "home-manager",
                        "rev": "bbb222",
                    }
                },
            },
        }
        (self.repo / "flake.nix").write_text("{}")
        (self.repo / "flake.lock").write_text(json.dumps(root_lock))
        # nested flake without a lock file: skipped
        (self.repo / "templates" / "rust").mkdir(parents=True)
        (self.repo / "templates" / "rust" / "flake.nix").write_text("{}")
        # nested flake with its own lock file
        sub_lock = {
            "root": "root",
            "nodes": {
                "root": {"inputs": {"foo": "foo"}},
                "foo": {
                    "locked": {
                        "type": "github",
                        "owner": "acme",
                        "repo": "foo",
                        "rev": "ddd444",
                    }
                },
            },
        }
        (self.repo / "sub").mkdir()
        (self.repo / "sub" / "flake.nix").write_text("{}")
        (self.repo / "sub" / "flake.lock").write_text(json.dumps(sub_lock))

    def discover(self, exclude: list[str] | None = None):
        with mock.patch("builtins.print"):
            return update_flake_inputs.discover_inputs(self.repo, exclude or [])

    def test_discover_inputs(self):
        inputs = self.discover()
        self.assertEqual(
            [inp.unit for inp in inputs],
            ["home-manager", "nixpkgs", "sub#foo"],
        )
        self.assertEqual(
            inputs[:2],
            [
                update_flake_inputs.FlakeInput(".", "home-manager"),
                update_flake_inputs.FlakeInput(".", "nixpkgs"),
            ],
        )
        self.assertEqual(inputs[2], update_flake_inputs.FlakeInput("sub", "foo"))

    def test_discover_exclude_nested_glob(self):
        units = [inp.unit for inp in self.discover(["sub#*"])]
        self.assertEqual(units, ["home-manager", "nixpkgs"])

    def test_discover_exclude_root_input(self):
        units = [inp.unit for inp in self.discover(["nixpkgs"])]
        self.assertEqual(units, ["home-manager", "sub#foo"])

    def test_branch_names(self):
        self.assertEqual(
            update_flake_inputs.FlakeInput(".", "nixpkgs").branch,
            "update-flake-input-nixpkgs",
        )
        self.assertEqual(
            update_flake_inputs.FlakeInput("sub", "foo").branch,
            "update-flake-input-sub-foo",
        )

    def test_locked_rev_returns_locked_dict(self):
        inp = update_flake_inputs.FlakeInput(".", "nixpkgs")
        self.assertEqual(
            update_flake_inputs._locked_rev(self.repo, inp),
            {"type": "github", "owner": "NixOS", "repo": "nixpkgs", "rev": "aaa111"},
        )

    def test_commit_message_github_diff_url(self):
        old = {"type": "github", "owner": "NixOS", "repo": "nixpkgs", "rev": "aaa111"}
        new = {"type": "github", "owner": "NixOS", "repo": "nixpkgs", "rev": "ccc333"}
        inp = update_flake_inputs.FlakeInput(".", "nixpkgs")
        msg = update_flake_inputs.commit_message(inp, old, new)
        self.assertEqual(
            msg,
            "flake: update nixpkgs\n\n"
            "Diff: https://github.com/NixOS/nixpkgs/compare/aaa111...ccc333",
        )

    def test_commit_message_nested_title(self):
        inp = update_flake_inputs.FlakeInput("sub", "foo")
        old = {"type": "github", "owner": "acme", "repo": "foo", "rev": "ddd444"}
        new = {"type": "github", "owner": "acme", "repo": "foo", "rev": "eee555"}
        msg = update_flake_inputs.commit_message(inp, old, new)
        self.assertEqual(
            msg,
            "flake: update sub#foo\n\n"
            "Diff: https://github.com/acme/foo/compare/ddd444...eee555",
        )

    def test_commit_message_no_old(self):
        new = {"type": "github", "owner": "NixOS", "repo": "nixpkgs", "rev": "ccc333"}
        inp = update_flake_inputs.FlakeInput(".", "nixpkgs")
        msg = update_flake_inputs.commit_message(inp, None, new)
        self.assertEqual(msg, "flake: update nixpkgs")

    def test_commit_message_non_github_no_diff(self):
        old = {"type": "git", "owner": "NixOS", "repo": "nixpkgs", "rev": "aaa111"}
        new = {"type": "git", "owner": "NixOS", "repo": "nixpkgs", "rev": "ccc333"}
        inp = update_flake_inputs.FlakeInput(".", "nixpkgs")
        msg = update_flake_inputs.commit_message(inp, old, new)
        self.assertEqual(msg, "flake: update nixpkgs")
        self.assertNotIn("Diff:", msg)


class TestParseOrigin(unittest.TestCase):
    def test_https_with_credentials(self):
        self.assertEqual(
            pipeline.parse_origin(
                "https://oauth2:tok@codeberg.org/fosskar/nixfiles.git"
            ),
            ("codeberg.org", "fosskar", "nixfiles"),
        )

    def test_plain_https_without_git_suffix(self):
        self.assertEqual(
            pipeline.parse_origin("https://github.com/owner/repo"),
            ("github.com", "owner", "repo"),
        )

    def test_ssh_scp_form(self):
        self.assertEqual(
            pipeline.parse_origin("git@github.com:o/r.git"),
            ("github.com", "o", "r"),
        )

    def test_non_owner_repo_path_exits(self):
        with self.assertRaises(SystemExit):
            pipeline.parse_origin("https://host/a/b/c")

    def test_unparseable_url_exits(self):
        with self.assertRaises(SystemExit):
            pipeline.parse_origin("/local/path")


class TestForgeRetryStatus(unittest.TestCase):
    def _exhaust(self, exc: Exception) -> ForgeError:
        cb = Codeberg("h", "o", "r", "tok")
        with (
            mock.patch("forge._BACKOFF", (0,)),
            mock.patch("forge.time.sleep"),
            mock.patch("forge.urllib.request.urlopen", side_effect=exc),
            contextlib.redirect_stdout(io.StringIO()),
        ):
            with self.assertRaises(ForgeError) as ctx:
                cb._request("GET", "https://h/x")
        return ctx.exception

    def test_exhausted_429_carries_status(self):
        err = urllib.error.HTTPError(
            "https://h/x", 429, "Too Many Requests", email.message.Message(), None
        )
        self.assertEqual(self._exhaust(err).status, 429)

    def test_exhausted_urlerror_has_no_status(self):
        self.assertIsNone(self._exhaust(urllib.error.URLError("down")).status)


class TestPublishSkipPush(unittest.TestCase):
    """Remote branch already up to date: never push, but ensure a PR exists."""

    BRANCH = "update-flake-input-nixpkgs"
    MESSAGE = "flake: update nixpkgs"

    def _publish(self, prs: list[dict], forge_mock: mock.Mock) -> int | None:
        self.run_cmds: list[list[str]] = []

        def fake_run(*, repo, cmd, check=True):
            self.run_cmds.append(cmd)
            return SimpleNamespace(returncode=0)  # fetch ok, diff --quiet clean

        def fake_capture(*, repo, cmd, check=True):
            if "rev-parse" in cmd:
                return SimpleNamespace(returncode=0, stdout="deadbeef\n")
            if "log" in cmd:
                return SimpleNamespace(returncode=0, stdout=self.MESSAGE + "\n")
            raise AssertionError(f"unexpected capture: {cmd}")

        with (
            mock.patch("pipeline.run", side_effect=fake_run),
            mock.patch("pipeline.capture", side_effect=fake_capture),
            mock.patch("pipeline.changelog.enrich", side_effect=lambda b: b),
            mock.patch("pipeline.BASE", "main"),
            contextlib.redirect_stdout(io.StringIO()),
        ):
            return pipeline.publish(
                Path("/repo"), self.BRANCH, self.MESSAGE, forge_mock, prs
            )

    def test_existing_pr_only_pokes_merge(self):
        forge_mock = mock.Mock()
        prs = [{"head": {"ref": self.BRANCH}, "base": {"ref": "main"}, "number": 7}]
        self.assertIsNone(self._publish(prs, forge_mock))
        forge_mock.merge_if_green.assert_called_once_with(7)
        forge_mock.create_pull.assert_not_called()

    def test_missing_pr_created_without_push(self):
        forge_mock = mock.Mock()
        forge_mock.create_pull.return_value = {"number": 12}
        prs: list[dict] = []
        self.assertEqual(self._publish(prs, forge_mock), 12)
        forge_mock.create_pull.assert_called_once_with(
            title=self.MESSAGE, head=self.BRANCH, base="main", body=self.MESSAGE
        )
        forge_mock.enable_automerge.assert_called_once_with(12)
        self.assertEqual(prs, [{"number": 12}])
        self.assertFalse(any("push" in cmd for cmd in self.run_cmds))


class TestRateLimitDeferral(unittest.TestCase):
    """A 429 from the forge defers the input; anything else is a failure."""

    def _main(self, exc: Exception) -> int:
        with (
            mock.patch("sys.argv", ["update_flake_inputs"]),
            mock.patch(
                "update_flake_inputs.discover_inputs",
                return_value=[FlakeInput(".", "nixpkgs")],
            ),
            mock.patch(
                "update_flake_inputs.pipeline.connect",
                return_value=(mock.Mock(), []),
            ),
            mock.patch("update_flake_inputs.pipeline.sweep"),
            mock.patch("update_flake_inputs.process_input", side_effect=exc),
            contextlib.redirect_stdout(io.StringIO()),
        ):
            return update_flake_inputs.main()

    def test_429_deferred_not_a_failure(self):
        self.assertEqual(self._main(ForgeError("throttled", status=429)), 0)

    def test_other_status_still_fails(self):
        self.assertEqual(self._main(ForgeError("boom", status=None)), 1)


class TestGithubRequestShape(unittest.TestCase):
    """merge_if_green must emit the exact GitHub REST merge request."""

    def test_merge_request_method_url_auth_body(self):
        gh = Github("github.com", "owner", "repo", "tok")
        urlopen = mock.MagicMock()
        urlopen.return_value.__enter__.return_value.read.return_value = b""
        with (
            mock.patch("forge.urllib.request.urlopen", urlopen),
            contextlib.redirect_stdout(io.StringIO()),
        ):
            gh.merge_if_green(7)
        req = urlopen.call_args[0][0]
        self.assertEqual(req.get_method(), "PUT")
        self.assertEqual(
            req.full_url, "https://api.github.com/repos/owner/repo/pulls/7/merge"
        )
        self.assertEqual(req.get_header("Authorization"), "Bearer tok")
        self.assertEqual(req.get_header("Accept"), "application/vnd.github+json")
        self.assertEqual(json.loads(req.data), {"merge_method": "squash"})


class TestGithubMergeIfGreen(unittest.TestCase):
    """405/409 are expected races and stay silent; other failures print."""

    def _merge(self, exc: Exception | None) -> str:
        gh = Github("github.com", "o", "r", "tok")
        urlopen = mock.MagicMock()
        if exc is not None:
            urlopen.side_effect = exc
        else:
            urlopen.return_value.__enter__.return_value.read.return_value = b""
        out = io.StringIO()
        with (
            mock.patch("forge._BACKOFF", (0,)),
            mock.patch("forge.time.sleep"),
            mock.patch("forge.urllib.request.urlopen", urlopen),
            contextlib.redirect_stdout(out),
        ):
            gh.merge_if_green(7)
        return out.getvalue()

    @staticmethod
    def _http_error(code: int) -> urllib.error.HTTPError:
        return urllib.error.HTTPError(
            "https://api.github.com/x",
            code,
            "err",
            email.message.Message(),
            io.BytesIO(b"detail"),
        )

    def test_405_silent(self):
        self.assertEqual(self._merge(self._http_error(405)), "")

    def test_409_silent(self):
        self.assertEqual(self._merge(self._http_error(409)), "")

    def test_other_status_prints_but_does_not_raise(self):
        self.assertIn("merge attempt failed", self._merge(self._http_error(403)))

    def test_success_prints_merged(self):
        self.assertIn("merged directly", self._merge(None))


class TestGithubEnableAutomerge(unittest.TestCase):
    """Automerge goes through GraphQL with the PR node id; never raises."""

    def _gh(self, side_effect) -> tuple[Github, mock.Mock, str]:
        gh = Github("github.com", "o", "r", "tok")
        gh._request = mock.Mock(side_effect=side_effect)
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            gh.enable_automerge(7)
        return gh, gh._request, out.getvalue()

    def test_graphql_mutation_carries_node_id(self):
        _, request, out = self._gh(
            [{"node_id": "PR_X"}, {"data": {"enablePullRequestAutoMerge": {}}}]
        )
        self.assertEqual(
            request.call_args_list[0],
            mock.call("GET", "https://api.github.com/repos/o/r/pulls/7"),
        )
        method, url, body = request.call_args_list[1][0]
        self.assertEqual((method, url), ("POST", "https://api.github.com/graphql"))
        self.assertEqual(body["variables"], {"id": "PR_X"})
        self.assertIn("enablePullRequestAutoMerge", body["query"])
        self.assertEqual(out, "")

    def test_graphql_errors_print_not_raise(self):
        _, _, out = self._gh(
            [{"node_id": "PR_X"}, {"errors": [{"message": "not allowed"}]}]
        )
        self.assertIn("not allowed", out)

    def test_forge_error_prints_not_raise(self):
        _, _, out = self._gh(ForgeError("boom", status=422))
        self.assertIn("boom", out)


class TestConnectDispatch(unittest.TestCase):
    """connect picks Github for github.com origins, Codeberg otherwise."""

    def _connect(self, url: str) -> object:
        def fake_capture(*, repo, cmd, check=True):
            if "status" in cmd:
                return SimpleNamespace(returncode=0, stdout="")
            if "get-url" in cmd:
                return SimpleNamespace(returncode=0, stdout=url + "\n")
            raise AssertionError(f"unexpected capture: {cmd}")

        with (
            mock.patch("pipeline.capture", side_effect=fake_capture),
            mock.patch("pipeline.run"),
            mock.patch("pipeline.default_branch", return_value="main"),
            mock.patch("pipeline.read_token", return_value="tok"),
            mock.patch.object(Github, "open_pulls", return_value=[]),
            mock.patch.object(Codeberg, "open_pulls", return_value=[]),
        ):
            forge, prs = pipeline.connect(Path("/repo"), dry_run=False)
        self.assertEqual(prs, [])
        return forge

    def test_github_host(self):
        self.assertIsInstance(self._connect("https://github.com/o/r.git"), Github)

    def test_codeberg_host(self):
        self.assertIsInstance(self._connect("https://codeberg.org/o/r.git"), Codeberg)


class TestParseUpdateScript(unittest.TestCase):
    """parse_update_script reads captured `nix eval .#<pkg>.updateScript --json`."""

    def test_nix_update_script_list_form(self):
        out = json.dumps(
            ["/nix/store/abc-nix-update/bin/nix-update", "--version-regex", "v(.*)"]
        )
        self.assertEqual(
            parse_update_script(out),
            ["/nix/store/abc-nix-update/bin/nix-update", "--version-regex", "v(.*)"],
        )

    def test_path_form_rejected(self):
        # updateScript = ./update.sh evals to a store-path string, not a list;
        # handled by the update.sh fallback instead.
        self.assertIsNone(parse_update_script(json.dumps("/nix/store/x-src/update.sh")))

    def test_null_rejected(self):
        # the updater package itself sets passthru.updateScript = null
        self.assertIsNone(parse_update_script("null"))


class TestClassify(unittest.TestCase):
    def test_update_script_wins_over_update_sh(self):
        self.assertEqual(classify(["nix-update"], has_update_sh=True), "nix-update")

    def test_update_sh_fallback(self):
        self.assertEqual(classify(None, has_update_sh=True), "script")

    def test_neither_skips(self):
        self.assertIsNone(classify(None, has_update_sh=False))


class TestNixUpdateCmd(unittest.TestCase):
    def test_store_path_head_stripped_args_kept(self):
        cmd = nix_update_cmd(
            "brave-origin",
            ["/nix/store/abc-nix-update/bin/nix-update", "--version-regex", "v(.*)"],
            "/tmp/m.msg",
        )
        self.assertEqual(
            cmd,
            [
                "nix-update",
                "--version-regex",
                "v(.*)",
                "--flake",
                "--write-commit-message",
                "/tmp/m.msg",
                "brave-origin",
            ],
        )

    def test_bare_nix_update_head(self):
        cmd = nix_update_cmd("voquill", ["nix-update", "--flake"], "/tmp/m.msg")
        self.assertEqual(cmd[:2], ["nix-update", "--flake"])
        self.assertEqual(cmd[-1], "voquill")

    def test_foreign_head_drops_args(self):
        # a list updateScript not headed by nix-update: args are not
        # nix-update flags, so only the package name is passed
        cmd = nix_update_cmd("pkg", ["/nix/store/x/bin/custom-update", "--foo"], "m")
        self.assertEqual(
            cmd, ["nix-update", "--flake", "--write-commit-message", "m", "pkg"]
        )

    def test_empty_script(self):
        cmd = nix_update_cmd("pkg", [], "m")
        self.assertEqual(
            cmd, ["nix-update", "--flake", "--write-commit-message", "m", "pkg"]
        )


if __name__ == "__main__":
    unittest.main()
