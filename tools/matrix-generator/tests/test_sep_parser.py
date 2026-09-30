"""Tests for SEP preamble handling in sep/sep_parser.py.

The fixtures are copies of ecosystem/sep-0029.md and ecosystem/sep-0053.md
from stellar/stellar-protocol master.
"""

import io
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

TOOLS_DIR = Path(__file__).resolve().parent.parent
for path in (TOOLS_DIR, TOOLS_DIR / 'sep'):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

import sep_parser  # noqa: E402
from sep_parser import SEPParser  # noqa: E402

FIXTURES_DIR = Path(__file__).resolve().parent / 'fixtures'

NO_CONTENT_MESSAGE = 'No content to parse. Call fetch_sep_markdown() first.'


def load_fixture(sep_number: str) -> str:
    return (FIXTURES_DIR / f'sep-{sep_number}.md').read_text(encoding='utf-8')


def replace_once(text: str, old: str, new: str) -> str:
    if text.count(old) != 1:
        raise AssertionError(f'{old!r} occurs {text.count(old)} times in the fixture')
    return text.replace(old, new)


def parse_markdown(sep_number: str, markdown: str) -> dict:
    parser = SEPParser(sep_number)
    parser.raw_content = markdown
    with redirect_stdout(io.StringIO()):
        return parser.parse()


class UpstreamPreambleTest(unittest.TestCase):
    """SEP-0029 and SEP-0053 take their preamble from the fetched document."""

    def test_sep_0029_preamble_matches_upstream(self):
        preamble = parse_markdown('0029', load_fixture('0029'))['preamble']

        self.assertEqual(preamble['title'], 'Account Memo Requirements')
        self.assertEqual(preamble['version'], '0.5.0')
        self.assertEqual(preamble['status'], 'Active')
        self.assertEqual(preamble['updated'], '2020-05-04')

    def test_sep_0053_preamble_matches_upstream(self):
        preamble = parse_markdown('0053', load_fixture('0053'))['preamble']

        self.assertEqual(preamble['title'], 'Sign and Verify Messages')
        self.assertEqual(preamble['version'], '1.0.0')
        self.assertEqual(preamble['status'], 'Final')
        self.assertEqual(preamble['updated'], '2026-06-18')

    def test_preamble_follows_an_edited_document(self):
        upstream_lines = {
            '0029': ('Version: 0.5.0', 'Status: Active'),
            '0053': ('Version: 1.0.0', 'Status: Final'),
        }
        for sep_number, (version_line, status_line) in upstream_lines.items():
            with self.subTest(sep=sep_number):
                markdown = load_fixture(sep_number)
                markdown = replace_once(markdown, version_line, 'Version: 7.3.1')
                markdown = replace_once(markdown, status_line, 'Status: Draft')

                preamble = parse_markdown(sep_number, markdown)['preamble']

                self.assertEqual(preamble['version'], '7.3.1')
                self.assertEqual(preamble['status'], 'Draft')


class UniformFetchTest(unittest.TestCase):
    """Every SEP, including 0029 and 0053, goes through the same fetch path."""

    def test_parser_has_no_hard_coded_sep_set(self):
        self.assertFalse(hasattr(SEPParser, 'HARDCODED_SEPS'))

    def test_parse_without_content_raises_for_every_sep(self):
        for sep_number in ('0001', '0010', '0029', '0053'):
            with self.subTest(sep=sep_number):
                with redirect_stdout(io.StringIO()):
                    with self.assertRaises(ValueError) as context:
                        SEPParser(sep_number).parse()
                self.assertEqual(str(context.exception), NO_CONTENT_MESSAGE)

    def run_main(self, sep_number: str, fetch_side_effect) -> tuple:
        with mock.patch.object(
            SEPParser, 'fetch_sep_markdown', autospec=True,
            side_effect=fetch_side_effect
        ) as fetch, mock.patch.object(
            SEPParser, 'save_to_file', autospec=True
        ) as save, mock.patch.object(
            sys, 'argv', ['sep_parser.py', sep_number]
        ), redirect_stdout(io.StringIO()):
            exit_code = sep_parser.main()
        return exit_code, fetch, save

    def test_main_fetches_sep_0029_and_0053(self):
        def fetch_fixture(parser):
            parser.raw_content = load_fixture(parser.sep_number)
            return True

        expected_versions = {'0029': '0.5.0', '0053': '1.0.0'}
        for sep_number, expected_version in expected_versions.items():
            with self.subTest(sep=sep_number):
                exit_code, fetch, save = self.run_main(sep_number, fetch_fixture)

                self.assertEqual(exit_code, 0)
                fetch.assert_called_once()
                self.assertEqual(fetch.call_args.args[0].sep_number, sep_number)
                saved = save.call_args.args[0].parsed_data
                self.assertEqual(saved['preamble']['version'], expected_version)

    def test_main_fails_when_the_fetch_fails(self):
        for sep_number in ('0029', '0053'):
            with self.subTest(sep=sep_number):
                exit_code, fetch, save = self.run_main(
                    sep_number, lambda parser: False
                )

                self.assertEqual(exit_code, 1)
                fetch.assert_called_once()
                save.assert_not_called()


if __name__ == '__main__':
    unittest.main()
