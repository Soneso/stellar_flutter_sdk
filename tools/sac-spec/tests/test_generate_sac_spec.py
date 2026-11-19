"""Tests for tools/sac-spec/generate_sac_spec.py, run offline on temporary directories."""

import base64
import contextlib
import hashlib
import io
import json
import os
import re
import shutil
import socket
import sys
import tempfile
import unittest
import urllib.error
from unittest import mock

SPEC_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if SPEC_DIR not in sys.path:
    sys.path.insert(0, SPEC_DIR)

import generate_sac_spec  # noqa: E402

REAL_PIN = os.path.join(SPEC_DIR, "pin.json")
REAL_TEMPLATE = os.path.join(SPEC_DIR, "sac_spec.dart.template")
REPO_ROOT = os.path.abspath(os.path.join(SPEC_DIR, os.pardir, os.pardir))
REAL_OUTPUT = os.path.join(REPO_ROOT, "lib", "src", "soroban", "sac_spec.dart")

TEMPLATE_RELATIVE = "tools/sac-spec/sac_spec.dart.template"
OUTPUT_RELATIVE = "lib/src/soroban/sac_spec.dart"

SOURCE = b"\x00\x01stellar asset spec\xff"
SPEC_SIZE = 9612
SPEC_BYTES = (bytes(range(256)) * 38)[:SPEC_SIZE]

MINIMAL_TEMPLATE = (
    "// {{FILE}} {{REPOSITORY}} {{COMMIT}} {{SIZE}} {{SHA256}}\n"
    'const String BASE64 = "{{BASE64}}";\n'
)


def sha256_hex(data):
    return hashlib.sha256(data).hexdigest()


class GeneratorTestCase(unittest.TestCase):
    """Builds a temporary root with a pin, a template and a source file."""

    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.tmp = temporary.name
        self.root = os.path.join(self.tmp, "root")
        os.makedirs(os.path.join(self.root, "tools", "sac-spec"))
        self.pin_path = os.path.join(self.tmp, "pin.json")
        self.source_path = os.path.join(self.tmp, "source.xdr")
        self.template_path = os.path.join(self.root, TEMPLATE_RELATIVE)
        self.output_path = os.path.join(self.root, OUTPUT_RELATIVE)
        self.write(self.template_path, MINIMAL_TEMPLATE)
        self.write(self.source_path, SOURCE)
        self.pin = {
            "repository": "example/spec-repo",
            "commit": "a" * 40,
            "file": "spec.xdr",
            "sha256": sha256_hex(SOURCE),
            "template": TEMPLATE_RELATIVE,
            "output": OUTPUT_RELATIVE,
        }
        self.write_pin(self.pin)

    def write(self, path, content):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        mode = "wb" if isinstance(content, bytes) else "w"
        with open(path, mode) as handle:
            handle.write(content)

    def write_pin(self, pin):
        self.write(self.pin_path, json.dumps(pin, indent=2) + "\n")

    def run_main(self, *extra):
        """Runs main with the temporary pin and root; returns (status, stdout, stderr)."""
        argv = ["--pin", self.pin_path, "--root", self.root] + list(extra)
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            status = generate_sac_spec.main(argv)
        return status, out.getvalue(), err.getvalue()

    def run_with_source(self, *extra):
        return self.run_main("--source", self.source_path, *extra)

    def assert_no_output(self):
        self.assertFalse(os.path.exists(self.output_path))
        self.assertFalse(os.path.exists(self.output_path + ".tmp"))


class SuccessTest(GeneratorTestCase):

    def test_fills_every_placeholder_and_exits_zero(self):
        status, _, err = self.run_with_source()
        self.assertEqual(status, 0, err)
        with open(self.output_path, "rb") as handle:
            output = handle.read()
        text = output.decode("utf-8")
        self.assertNotIn("{{", text)
        self.assertIn("spec.xdr", text)
        self.assertIn("example/spec-repo", text)
        self.assertIn("a" * 40, text)
        self.assertIn(str(len(SOURCE)), text)
        self.assertIn(sha256_hex(SOURCE), text)
        match = re.search(r'BASE64 = "([^"]*)"', text)
        self.assertIsNotNone(match)
        self.assertEqual(base64.b64decode(match.group(1)), SOURCE)

    def test_output_uses_lf_endings_and_ends_with_newline(self):
        self.write(self.template_path, MINIMAL_TEMPLATE.replace("\n", "\r\n"))
        status, _, err = self.run_with_source()
        self.assertEqual(status, 0, err)
        with open(self.output_path, "rb") as handle:
            output = handle.read()
        self.assertNotIn(b"\r", output)
        self.assertTrue(output.endswith(b"\n"))

    def test_two_runs_produce_identical_bytes(self):
        self.assertEqual(self.run_with_source()[0], 0)
        with open(self.output_path, "rb") as handle:
            first = handle.read()
        self.assertEqual(self.run_with_source()[0], 0)
        with open(self.output_path, "rb") as handle:
            second = handle.read()
        self.assertEqual(first, second)

    def test_no_temporary_file_is_left_behind(self):
        self.assertEqual(self.run_with_source()[0], 0)
        self.assertFalse(os.path.exists(self.output_path + ".tmp"))

    def test_source_is_not_downloaded(self):
        with mock.patch.object(generate_sac_spec.urllib.request, "urlopen") as urlopen:
            self.assertEqual(self.run_with_source()[0], 0)
        urlopen.assert_not_called()


class DownloadTest(GeneratorTestCase):

    def fake_response(self, data):
        response = mock.MagicMock()
        response.read.return_value = data
        context = mock.MagicMock()
        context.__enter__.return_value = response
        context.__exit__.return_value = False
        return context

    def test_downloads_the_raw_url_with_a_sixty_second_timeout(self):
        url = "https://raw.githubusercontent.com/example/spec-repo/" + "a" * 40 + "/spec.xdr"
        with mock.patch.object(
            generate_sac_spec.urllib.request, "urlopen", return_value=self.fake_response(SOURCE)
        ) as urlopen:
            status, _, err = self.run_main()
        self.assertEqual(status, 0, err)
        urlopen.assert_called_once_with(url, timeout=60)
        self.assertEqual(generate_sac_spec.DOWNLOAD_TIMEOUT_SECONDS, 60)

    def test_digest_mismatch_after_download_writes_nothing(self):
        with mock.patch.object(
            generate_sac_spec.urllib.request, "urlopen", return_value=self.fake_response(b"other")
        ):
            status, _, err = self.run_main()
        self.assertEqual(status, 1)
        self.assertIn(sha256_hex(b"other"), err)
        self.assert_no_output()

    def test_url_error_exits_one_and_names_the_url(self):
        with mock.patch.object(
            generate_sac_spec.urllib.request,
            "urlopen",
            side_effect=urllib.error.URLError("name resolution failed"),
        ):
            status, _, err = self.run_main()
        self.assertEqual(status, 1)
        self.assertIn("https://raw.githubusercontent.com/example/spec-repo/", err)
        self.assertIn("name resolution failed", err)
        self.assert_no_output()

    def test_http_error_exits_one_with_the_status(self):
        error = urllib.error.HTTPError("https://example.invalid/x", 404, "Not Found", None, None)
        with mock.patch.object(generate_sac_spec.urllib.request, "urlopen", side_effect=error):
            status, _, err = self.run_main()
        self.assertEqual(status, 1)
        self.assertIn("HTTP 404 Not Found", err)
        self.assertIn("raw.githubusercontent.com", err)
        self.assert_no_output()

    def test_malformed_url_exits_one_names_the_url_and_writes_nothing(self):
        self.write_pin(dict(self.pin, repository="bad repo[x"))
        url = "https://raw.githubusercontent.com/bad repo[x/" + "a" * 40 + "/spec.xdr"
        with mock.patch.object(
            generate_sac_spec.urllib.request,
            "urlopen",
            side_effect=ValueError("Invalid IPv6 URL"),
        ):
            status, _, err = self.run_main()
        self.assertEqual(status, 1)
        self.assertIn(url, err)
        self.assertIn("Invalid IPv6 URL", err)
        self.assertNotIn("Traceback", err)
        self.assert_no_output()

    def test_timeout_exits_one_and_names_the_url(self):
        with mock.patch.object(
            generate_sac_spec.urllib.request, "urlopen", side_effect=socket.timeout("timed out")
        ):
            status, _, err = self.run_main()
        self.assertEqual(status, 1)
        self.assertIn("raw.githubusercontent.com", err)
        self.assertIn("timed out", err)
        self.assert_no_output()


class DigestMismatchTest(GeneratorTestCase):

    def test_mismatch_prints_both_digests_writes_nothing_and_exits_one(self):
        wrong = "b" * 64
        self.pin["sha256"] = wrong
        self.write_pin(self.pin)
        status, out, err = self.run_with_source()
        self.assertEqual(status, 1)
        self.assertIn(wrong, err)
        self.assertIn(sha256_hex(SOURCE), err)
        self.assertEqual(out, "")
        self.assert_no_output()

    def test_mismatch_leaves_an_existing_output_untouched(self):
        self.write(self.output_path, "previous content\n")
        self.pin["sha256"] = "c" * 64
        self.write_pin(self.pin)
        self.assertEqual(self.run_with_source()[0], 1)
        with open(self.output_path, encoding="utf-8") as handle:
            self.assertEqual(handle.read(), "previous content\n")
        self.assertFalse(os.path.exists(self.output_path + ".tmp"))


class LeftoverPlaceholderTest(GeneratorTestCase):

    def test_unknown_placeholder_exits_one_and_writes_nothing(self):
        self.write(self.template_path, MINIMAL_TEMPLATE + "// {{UNKNOWN}}\n")
        status, _, err = self.run_with_source()
        self.assertEqual(status, 1)
        self.assertIn("{{UNKNOWN}}", err)
        self.assertIn("line 3", err)
        self.assert_no_output()

    def test_unterminated_placeholder_exits_one(self):
        self.write(self.template_path, "const String X = \"{{\";\n")
        status, _, err = self.run_with_source()
        self.assertEqual(status, 1)
        self.assertIn("{{", err)
        self.assert_no_output()


class FileErrorTest(GeneratorTestCase):

    def test_missing_source_names_the_path(self):
        missing = os.path.join(self.tmp, "absent.xdr")
        status, _, err = self.run_main("--source", missing)
        self.assertEqual(status, 1)
        self.assertIn(missing, err)
        self.assert_no_output()

    def test_source_that_is_a_directory_exits_one(self):
        status, _, err = self.run_main("--source", self.tmp)
        self.assertEqual(status, 1)
        self.assertIn(self.tmp, err)

    def test_missing_pin_names_the_path(self):
        os.remove(self.pin_path)
        status, _, err = self.run_with_source()
        self.assertEqual(status, 1)
        self.assertIn(self.pin_path, err)

    def test_invalid_json_pin_names_the_path(self):
        self.write(self.pin_path, "{not json")
        status, _, err = self.run_with_source()
        self.assertEqual(status, 1)
        self.assertIn(self.pin_path, err)
        self.assertIn("not valid JSON", err)

    def test_pin_that_is_not_an_object_exits_one(self):
        self.write(self.pin_path, "[]")
        status, _, err = self.run_with_source()
        self.assertEqual(status, 1)
        self.assertIn("JSON object", err)

    def test_missing_template_names_the_path(self):
        os.remove(self.template_path)
        status, _, err = self.run_with_source()
        self.assertEqual(status, 1)
        self.assertIn(self.template_path, err)
        self.assert_no_output()

    def test_template_that_is_not_utf8_exits_one(self):
        self.write(self.template_path, b"\xff\xfe bad")
        status, _, err = self.run_with_source()
        self.assertEqual(status, 1)
        self.assertIn("not valid UTF-8", err)

    def test_output_that_cannot_be_written_names_the_path(self):
        os.makedirs(self.output_path)
        status, _, err = self.run_with_source()
        self.assertEqual(status, 1)
        self.assertIn(self.output_path, err)
        self.assertFalse(os.path.exists(self.output_path + ".tmp"))


class EmbeddedNulTest(GeneratorTestCase):
    """A path with an embedded NUL byte fails cleanly, naming the path, not with a traceback."""

    def assert_clean_failure(self, status, err, fragment):
        self.assertEqual(status, 1)
        self.assertIn(fragment, err)
        self.assertNotIn("Traceback", err)

    def test_template_path_with_nul_exits_one(self):
        # A NUL in the root reaches the template read; a pin value cannot, because
        # control characters are rejected while the pin is loaded.
        err = io.StringIO()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(err):
            status = generate_sac_spec.main(
                ["--pin", self.pin_path, "--root", self.root + "\x00", "--source", self.source_path]
            )
        self.assert_clean_failure(status, err.getvalue(), "cannot read template")
        self.assertIn("tools/sac-spec/sac_spec.dart.template", err.getvalue())
        self.assert_no_output()

    def test_write_atomic_reports_a_nul_path_as_a_generation_error(self):
        path = os.path.join(self.root, "lib\x00", "sac_spec.dart")
        with self.assertRaises(generate_sac_spec.GenerationError) as context:
            generate_sac_spec.write_atomic(path, "x")
        self.assertIn("cannot write", str(context.exception))
        self.assertIn(generate_sac_spec.escape_control(path), str(context.exception))
        self.assert_no_output()

    def test_output_path_with_nul_exits_one_and_writes_nothing(self):
        self.write_pin(dict(self.pin, output="lib/src\x00/sac_spec.dart"))
        status, _, err = self.run_with_source()
        self.assert_clean_failure(status, err, "pin key 'output'")
        self.assertIn(self.pin_path, err)
        written = [
            name
            for _, _, names in os.walk(self.root)
            for name in names
            if name in ("sac_spec.dart", "sac_spec.dart.tmp")
        ]
        self.assertEqual(written, [])

    def test_source_path_with_nul_exits_one(self):
        status, _, err = self.run_main("--source", self.source_path + "\x00")
        self.assert_clean_failure(status, err, "cannot read source file")
        self.assertIn(self.source_path, err)
        self.assert_no_output()

    def test_nul_in_repository_value_exits_one_and_writes_nothing(self):
        self.write_pin(dict(self.pin, repository="example/spec\x00repo"))
        status, _, err = self.run_with_source()
        self.assert_clean_failure(status, err, "pin key 'repository'")
        self.assertIn(self.pin_path, err)
        self.assert_no_output()

    def test_nul_in_file_value_exits_one_and_writes_nothing(self):
        self.write_pin(dict(self.pin, file="spec\x00.xdr"))
        status, _, err = self.run_with_source()
        self.assert_clean_failure(status, err, "pin key 'file'")
        self.assertIn(self.pin_path, err)
        self.assert_no_output()

    def test_newline_in_source_path_exits_one_on_one_line_and_writes_nothing(self):
        source = os.path.join(self.tmp, "absent\nsource.xdr")
        line = self.assert_one_line_failure(source, "absent\\x0asource.xdr")
        self.assertIn(generate_sac_spec.escape_control(source), line)

    def assert_one_line_failure(self, source, escaped):
        """Runs main with a failing source and returns its single stderr line."""
        err = io.StringIO()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(err):
            status = generate_sac_spec.main(
                ["--pin", self.pin_path, "--root", self.root, "--source", source]
            )
        self.assertEqual(status, 1)
        lines = err.getvalue().splitlines()
        self.assertEqual(len(lines), 1, lines)
        self.assertIn(escaped, lines[0])
        self.assertNotIn("Traceback", err.getvalue())
        self.assert_no_output()
        return lines[0]

    def test_c1_control_in_source_path_exits_one_on_one_line(self):
        self.assert_one_line_failure(
            os.path.join(self.tmp, "absent\x85source.xdr"), "absent\\x85source.xdr"
        )

    def test_line_separator_in_source_path_exits_one_on_one_line(self):
        self.assert_one_line_failure(
            os.path.join(self.tmp, "absent\u2028source.xdr"), "absent\\u2028source.xdr"
        )

    def test_control_pattern_matches_c0_c1_and_line_separators(self):
        for character in ("\x00", "\x85", "\u2028", "\u2029"):
            self.assertIsNotNone(
                generate_sac_spec.CONTROL_PATTERN.search(character), repr(character)
            )
        self.assertIsNone(generate_sac_spec.CONTROL_PATTERN.search("a/b.xdr"))

    def test_pin_path_with_nul_exits_one(self):
        err = io.StringIO()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(err):
            status = generate_sac_spec.main(
                ["--pin", self.pin_path + "\x00", "--root", self.root, "--source", self.source_path]
            )
        self.assert_clean_failure(status, err.getvalue(), "cannot read pin file")
        self.assertIn(self.pin_path, err.getvalue())
        self.assert_no_output()


class PinValidationTest(GeneratorTestCase):

    def assert_pin_rejected(self, key, value, fragment):
        pin = dict(self.pin)
        if value is None:
            del pin[key]
        else:
            pin[key] = value
        self.write_pin(pin)
        status, _, err = self.run_with_source()
        self.assertEqual(status, 1)
        self.assertIn(fragment, err)
        self.assert_no_output()

    def test_missing_key_is_named(self):
        self.assert_pin_rejected("commit", None, "'commit'")

    def test_empty_value_is_rejected(self):
        self.assert_pin_rejected("file", "", "'file'")

    def test_non_string_value_is_rejected(self):
        self.assert_pin_rejected("repository", 7, "'repository'")

    def test_short_commit_is_rejected(self):
        self.assert_pin_rejected("commit", "a" * 39, "40 lowercase hex")

    def test_uppercase_commit_is_rejected(self):
        self.assert_pin_rejected("commit", "A" * 40, "40 lowercase hex")

    def test_short_sha256_is_rejected(self):
        self.assert_pin_rejected("sha256", "a" * 63, "64 lowercase hex")

    def test_uppercase_sha256_is_rejected(self):
        self.assert_pin_rejected("sha256", "A" * 64, "64 lowercase hex")

    def test_absolute_template_path_is_rejected(self):
        self.assert_pin_rejected("template", "/etc/passwd", "relative to the root")


class RenderTest(GeneratorTestCase):

    def test_size_and_header_follow_the_source_length(self):
        self.write(self.source_path, SPEC_BYTES)
        self.pin["sha256"] = sha256_hex(SPEC_BYTES)
        self.write_pin(self.pin)
        self.assertEqual(self.run_with_source()[0], 0)
        with open(self.output_path, encoding="utf-8") as handle:
            text = handle.read()
        self.assertIn(" 9612 " + sha256_hex(SPEC_BYTES), text)

    def test_placeholder_text_in_a_pin_value_is_caught_as_a_leftover(self):
        self.write_pin(dict(self.pin, repository="x{{SHA256}}y"))
        status, _, err = self.run_with_source()
        self.assertEqual(status, 1)
        self.assertIn("unfilled placeholder", err)
        self.assert_no_output()


class DefaultPathsTest(GeneratorTestCase):
    """The defaults of --pin and --root resolve beside the script and to the repository root."""

    def test_defaults_are_the_pin_beside_the_script_and_the_repository_root(self):
        with mock.patch.object(generate_sac_spec, "run", return_value=0) as run:
            status = generate_sac_spec.main(["--source", self.source_path])
        self.assertEqual(status, 0)
        args = run.call_args[0][0]
        self.assertEqual(args.pin, os.path.join(SPEC_DIR, "pin.json"))
        self.assertTrue(os.path.isfile(args.pin))
        self.assertEqual(os.path.abspath(args.root), REPO_ROOT)
        self.assertTrue(os.path.isfile(os.path.join(args.root, TEMPLATE_RELATIVE)))

    def test_default_pin_and_root_generate_under_the_patched_root(self):
        with mock.patch.object(generate_sac_spec, "DEFAULT_PIN", self.pin_path), mock.patch.object(
            generate_sac_spec, "DEFAULT_ROOT", self.root
        ):
            err = io.StringIO()
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(err):
                status = generate_sac_spec.main(["--source", self.source_path])
        self.assertEqual(status, 0, err.getvalue())
        self.assertTrue(os.path.isfile(self.output_path))


class RealPinAndTemplateTest(unittest.TestCase):
    """Checks the committed pin and template against the values of the contract."""

    def setUp(self):
        with open(REAL_PIN, encoding="utf-8") as handle:
            self.pin = json.load(handle)

    def test_pin_holds_the_contract_values(self):
        self.assertEqual(self.pin["repository"], "stellar/stellar-asset-contract-spec")
        self.assertEqual(self.pin["commit"], "4f08d14f8b3e09e195f2cc4aab51c7f8a34f52ea")
        self.assertEqual(self.pin["file"], "stellar-asset-spec.xdr")
        self.assertEqual(
            self.pin["sha256"],
            "a88030febc66645d40b96deba8be16a6eb13c213768b4c1f9cd6278080d74669",
        )
        self.assertEqual(self.pin["template"], TEMPLATE_RELATIVE)
        self.assertEqual(self.pin["output"], OUTPUT_RELATIVE)

    def test_committed_template_renders_the_spec_layout(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = os.path.join(tmp.name, "root")
        os.makedirs(os.path.join(root, "tools", "sac-spec"))
        shutil.copy(REAL_TEMPLATE, os.path.join(root, TEMPLATE_RELATIVE))
        source = os.path.join(tmp.name, "spec.xdr")
        with open(source, "wb") as handle:
            handle.write(SPEC_BYTES)
        pin = dict(self.pin, sha256=sha256_hex(SPEC_BYTES))
        pin_path = os.path.join(tmp.name, "pin.json")
        with open(pin_path, "w", encoding="utf-8") as handle:
            json.dump(pin, handle)
        err = io.StringIO()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(err):
            status = generate_sac_spec.main(
                ["--pin", pin_path, "--root", root, "--source", source]
            )
        self.assertEqual(status, 0, err.getvalue())
        with open(os.path.join(root, OUTPUT_RELATIVE), encoding="utf-8") as handle:
            text = handle.read()
        self.assertNotIn("{{", text)
        self.assertIn("9612 bytes", text)
        self.assertIn(sha256_hex(SPEC_BYTES), text)
        self.assertIn("abstract final class SACSpec", text)
        match = re.search(r'XDR_BASE64 =\s*"([^"]*)";', text)
        self.assertIsNotNone(match)
        self.assertEqual(len(match.group(1)), 12816)
        self.assertEqual(base64.b64decode(match.group(1)), SPEC_BYTES)

    def test_committed_output_embeds_the_pinned_spec(self):
        with open(REAL_OUTPUT, encoding="utf-8") as handle:
            text = handle.read()
        self.assertIn("9612 bytes", text)
        self.assertIn(self.pin["sha256"], text)
        self.assertIn(self.pin["commit"], text)
        match = re.search(r'XDR_BASE64 =\s*"([^"]*)";', text)
        self.assertIsNotNone(match)
        spec = base64.b64decode(match.group(1))
        self.assertEqual(len(spec), 9612)
        self.assertEqual(hashlib.sha256(spec).hexdigest(), self.pin["sha256"])


if __name__ == "__main__":
    unittest.main()
