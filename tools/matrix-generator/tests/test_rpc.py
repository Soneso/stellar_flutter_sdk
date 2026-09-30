"""Tests for stellar-rpc release selection and response struct fetching.

Every HTTP request goes to a fake urlopen that serves canned bodies by URL and
answers 404 for any other URL.
"""

import email.message
import io
import json
import sys
import tempfile
import unittest
import urllib.error
from contextlib import redirect_stdout
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Sequence
from unittest import mock

TOOLS_DIR = Path(__file__).resolve().parent.parent
for path in (TOOLS_DIR, TOOLS_DIR / 'rpc'):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

import common  # noqa: E402
import generate_rpc_comparison  # noqa: E402
import github_fetcher  # noqa: E402
from github_fetcher import (  # noqa: E402
    GitHubFetchError,
    GitHubRelease,
    ReleaseNotFoundError,
    SourceFileNotFoundError,
    fetch_all_rpc_response_files,
    get_latest_rpc_release,
    get_rpc_release,
)
from rpc_parser import RPCMethodParser  # noqa: E402
from run_rpc_analysis import RPCAnalysisPipeline  # noqa: E402

RELEASES_PAGE_1 = 'https://api.github.com/repos/stellar/stellar-rpc/releases?per_page=100'
RELEASES_PAGE_2 = 'https://api.github.com/repositories/1/releases?per_page=100&page=2'

GO_STELLAR_SDK_REF = 'v0.7.3'

GO_MOD = (
    'module github.com/stellar/stellar-rpc\n\n'
    'go 1.24\n\n'
    'require (\n'
    f'\tgithub.com/stellar/go-stellar-sdk {GO_STELLAR_SDK_REF}\n'
    ')\n'
)

JSONRPC_SOURCE = '''package internal

func NewJSONRPCHandler() {
\thandlers := []struct {
\t\tmethodName string
\t}{
\t\t{
\t\t\tmethodName: protocol.GetHealthMethodName,
\t\t},
\t\t{
\t\t\tmethodName: protocol.GetNetworkMethodName,
\t\t},
\t}
}
'''

RESPONSE_FILES = {
    'get_health': '''package protocol

type GetHealthResponse struct {
\tStatus                string `json:"status"`
\tLatestLedger          uint32 `json:"latestLedger"`
\tOldestLedger          uint32 `json:"oldestLedger"`
\tLedgerRetentionWindow uint32 `json:"ledgerRetentionWindow"`
}
''',
    'get_network': '''package protocol

type GetNetworkResponse struct {
\tFriendbotURL    string `json:"friendbotUrl,omitempty"`
\tPassphrase      string `json:"passphrase"`
\tProtocolVersion int    `json:"protocolVersion"`
}
''',
}


def jsonrpc_url(tag: str) -> str:
    return (
        f'https://raw.githubusercontent.com/stellar/stellar-rpc/{tag}'
        f'/cmd/stellar-rpc/internal/jsonrpc.go'
    )


def go_mod_url(tag: str) -> str:
    return f'https://raw.githubusercontent.com/stellar/stellar-rpc/{tag}/go.mod'


def response_file_url(snake_name: str) -> str:
    return (
        f'https://raw.githubusercontent.com/stellar/go-stellar-sdk/'
        f'{GO_STELLAR_SDK_REF}/protocols/rpc/{snake_name}.go'
    )


def release_url(tag: str) -> str:
    return f'https://github.com/stellar/stellar-rpc/releases/tag/{tag}'


def release_record(
    tag: str,
    *,
    prerelease: bool = False,
    published_at: Optional[str] = '2026-08-27T18:40:46Z'
) -> Dict:
    return {
        'tag_name': tag,
        'draft': False,
        'prerelease': prerelease,
        'published_at': published_at,
        'html_url': release_url(tag),
        'target_commitish': 'main',
    }


def draft_record(tag: str) -> Dict:
    record = release_record(tag, published_at=None)
    record['draft'] = True
    return record


class FakeResponse:
    def __init__(self, body: bytes, link: Optional[str]):
        self._body = body
        self.headers = email.message.Message()
        if link is not None:
            self.headers['Link'] = link

    def read(self) -> bytes:
        return self._body

    def __enter__(self) -> 'FakeResponse':
        return self

    def __exit__(self, *exc_info) -> bool:
        return False


class FakeGitHub:
    """Serves canned responses by URL and records every requested URL."""

    # Upper bound on requests per test; a pagination regression hits it.
    MAX_REQUESTS = 50

    def __init__(self):
        self.responses: Dict[str, FakeResponse] = {}
        self.requested: List[str] = []

    def add(self, url: str, body, link: Optional[str] = None) -> None:
        if isinstance(body, str):
            body = body.encode('utf-8')
        self.responses[url] = FakeResponse(body, link)

    def urlopen(self, request, timeout=None) -> FakeResponse:
        url = request.full_url
        self.requested.append(url)
        if len(self.requested) > self.MAX_REQUESTS:
            raise AssertionError(f'more than {self.MAX_REQUESTS} requests')
        if url not in self.responses:
            raise urllib.error.HTTPError(
                url, 404, 'Not Found', email.message.Message(), None
            )
        return self.responses[url]


class FakeGitHubTestCase(unittest.TestCase):
    def setUp(self):
        self.github = FakeGitHub()
        patchers = (
            mock.patch('urllib.request.urlopen', self.github.urlopen),
            mock.patch.object(github_fetcher, 'get_github_token', return_value=None),
            mock.patch.dict(github_fetcher._GO_STELLAR_SDK_REF_CACHE, clear=True),
        )
        for patcher in patchers:
            patcher.start()
            self.addCleanup(patcher.stop)

    def serve_releases(
        self,
        records: Sequence,
        url: str = RELEASES_PAGE_1,
        next_url: Optional[str] = None
    ) -> None:
        link = f'<{next_url}>; rel="next", <{next_url}>; rel="last"' if next_url else None
        self.github.add(url, json.dumps(list(records)), link)

    def assert_selects(self, records: Sequence, expected_tag: str) -> None:
        self.serve_releases(records)
        self.assertEqual(get_latest_rpc_release().version, expected_tag)


class NewestStableReleaseTest(FakeGitHubTestCase):
    def test_selects_newest_stable_release_from_a_mixed_list(self):
        self.serve_releases([
            release_record('rpcclient-v24.0.0', published_at='2025-10-21T19:42:38Z'),
            draft_record('v30.0.0'),
            release_record('v29.0.0-rc.1', prerelease=True),
            release_record('v28.1.0', prerelease=True),
            release_record('v27.1.1', published_at='2026-07-07T21:51:04Z'),
            release_record('v28.0.0', published_at='2026-08-17T17:57:22Z'),
        ], next_url=RELEASES_PAGE_2)
        self.serve_releases([
            release_record('v28.0.1', published_at='2026-08-27T18:40:46Z'),
            release_record('v26.0.0', published_at='2026-04-03T21:03:53Z'),
        ], url=RELEASES_PAGE_2)

        release = get_latest_rpc_release()

        self.assertEqual(release.version, 'v28.0.1')
        self.assertEqual(release.published_at, datetime(2026, 8, 27, 18, 40, 46))
        self.assertEqual(release.html_url, release_url('v28.0.1'))
        self.assertEqual(self.github.requested, [RELEASES_PAGE_1, RELEASES_PAGE_2])

    def test_skips_client_library_tags(self):
        self.assert_selects(
            [release_record('rpcclient-v99.0.0'), release_record('v28.0.1')],
            'v28.0.1'
        )

    def test_skips_suffixed_tags_without_prerelease_flag(self):
        self.assert_selects(
            [release_record('v29.0.0-rc.1'), release_record('v28.0.1')],
            'v28.0.1'
        )

    def test_skips_suffixless_tag_flagged_prerelease(self):
        self.assert_selects(
            [release_record('v28.1.0', prerelease=True), release_record('v28.0.1')],
            'v28.0.1'
        )

    def test_filters_drafts_before_building_a_release(self):
        with mock.patch.object(
            GitHubRelease, 'from_api_response',
            wraps=GitHubRelease.from_api_response
        ) as build:
            self.assert_selects(
                [draft_record('v30.0.0'), release_record('v28.0.1')],
                'v28.0.1'
            )

        built_tags = [call.args[0]['tag_name'] for call in build.call_args_list]
        self.assertEqual(built_tags, ['v28.0.1'])

    def test_orders_by_version_not_list_position(self):
        self.assert_selects(
            [
                release_record('v27.1.1'),
                release_record('v28.0.1'),
                release_record('v28.0.0'),
            ],
            'v28.0.1'
        )

    def test_compares_version_parts_as_numbers(self):
        self.assert_selects(
            [
                release_record('v9.0.0'),
                release_record('v10.0.9'),
                release_record('v10.0.10'),
            ],
            'v10.0.10'
        )

    def test_follows_the_link_header_to_the_next_page(self):
        self.serve_releases([release_record('v27.0.0')], next_url=RELEASES_PAGE_2)
        self.serve_releases([release_record('v28.0.1')], url=RELEASES_PAGE_2)

        self.assertEqual(get_latest_rpc_release().version, 'v28.0.1')
        self.assertEqual(self.github.requested, [RELEASES_PAGE_1, RELEASES_PAGE_2])

    def test_empty_list_raises(self):
        self.serve_releases([])

        with self.assertRaisesRegex(ReleaseNotFoundError, 'No stable stellar-rpc release'):
            get_latest_rpc_release()

    def test_list_without_a_stable_release_raises(self):
        self.serve_releases([
            release_record('rpcclient-v24.0.0'),
            release_record('v29.0.0-rc.1', prerelease=True),
            draft_record('v30.0.0'),
        ])

        with self.assertRaisesRegex(ReleaseNotFoundError, 'No stable stellar-rpc release'):
            get_latest_rpc_release()


class InvalidReleaseListTest(FakeGitHubTestCase):
    def assert_fetch_error(self, pattern: str) -> None:
        with self.assertRaisesRegex(GitHubFetchError, pattern) as context:
            get_latest_rpc_release()
        self.assertNotIsInstance(context.exception, ReleaseNotFoundError)

    def test_body_that_is_not_json(self):
        self.github.add(RELEASES_PAGE_1, b'<html>unavailable</html>')
        self.assert_fetch_error('Invalid JSON')

    def test_body_that_is_not_an_array(self):
        self.github.add(RELEASES_PAGE_1, '{"message": "Not Found"}')
        self.assert_fetch_error('not a JSON array')

    def test_record_without_release_flags(self):
        self.github.add(
            RELEASES_PAGE_1,
            json.dumps([{'tag_name': 'v28.0.1', 'html_url': release_url('v28.0.1')}])
        )
        self.assert_fetch_error('Invalid release record')

    def test_selected_record_with_malformed_date(self):
        for published_at in ('27 Aug 2026', 20260827):
            with self.subTest(published_at=published_at):
                self.serve_releases([release_record('v28.0.1', published_at=published_at)])
                self.assert_fetch_error('Invalid published_at')

    def test_selected_record_without_html_url(self):
        record = release_record('v28.0.1')
        del record['html_url']
        self.serve_releases([record])
        self.assert_fetch_error("Missing field 'html_url'")

    def test_pagination_that_repeats_a_page(self):
        self.serve_releases([release_record('v28.0.1')], next_url=RELEASES_PAGE_1)
        self.assert_fetch_error('pagination repeats')

    def test_http_error(self):
        self.assert_fetch_error('HTTP 404')


class ReleaseOverrideTest(FakeGitHubTestCase):
    def setUp(self):
        super().setUp()
        self.serve_releases([
            release_record('v28.0.1'),
            draft_record('v30.0.0'),
            release_record('v29.0.0-rc.1', prerelease=True,
                           published_at='2026-09-20T10:00:00Z'),
            release_record('rpcclient-v24.0.0', published_at='2025-10-21T19:42:38Z'),
            release_record('v27.1.1', published_at='2026-07-07T21:51:04Z'),
        ])

    def test_override_returns_its_own_record(self):
        release = get_rpc_release('v27.1.1')

        self.assertEqual(release.version, 'v27.1.1')
        self.assertEqual(release.published_at, datetime(2026, 7, 7, 21, 51, 4))
        self.assertEqual(release.html_url, release_url('v27.1.1'))

    def test_prerelease_override_is_accepted(self):
        release = get_rpc_release('v29.0.0-rc.1')

        self.assertEqual(release.version, 'v29.0.0-rc.1')
        self.assertEqual(release.published_at, datetime(2026, 9, 20, 10, 0, 0))

    def test_absent_override_raises(self):
        with self.assertRaisesRegex(ReleaseNotFoundError, 'v99.0.0 is not in the release list'):
            get_rpc_release('v99.0.0')

    def test_draft_override_raises(self):
        with self.assertRaisesRegex(ReleaseNotFoundError, 'v30.0.0 is a draft'):
            get_rpc_release('v30.0.0')

    def test_client_library_override_raises(self):
        with self.assertRaisesRegex(
            ReleaseNotFoundError,
            "'rpcclient-v24.0.0' is not a stellar-rpc release tag"
        ):
            get_rpc_release('rpcclient-v24.0.0')


class ResponseFileFetchTest(unittest.TestCase):
    METHODS = ['getHealth', 'getEvents', 'getNetwork']

    def patch_fetch(self, failing: Optional[str]) -> List[str]:
        """Patch the single-file fetch; return the list it records calls in."""
        calls: List[str] = []

        def fetch(tag, snake_name):
            calls.append(snake_name)
            if snake_name == failing:
                raise SourceFileNotFoundError(f'Failed to fetch {snake_name}.go')
            return f'// {snake_name}'

        patcher = mock.patch.object(
            github_fetcher, 'fetch_rpc_response_file', side_effect=fetch
        )
        patcher.start()
        self.addCleanup(patcher.stop)
        return calls

    def test_returns_the_file_of_every_method(self):
        self.patch_fetch(failing=None)

        self.assertEqual(fetch_all_rpc_response_files('v28.0.1', self.METHODS), {
            'getHealth': '// get_health',
            'getEvents': '// get_events',
            'getNetwork': '// get_network',
        })

    def test_first_failed_file_raises(self):
        calls = self.patch_fetch(failing='get_events')

        with self.assertRaisesRegex(SourceFileNotFoundError, 'get_events'):
            fetch_all_rpc_response_files('v28.0.1', self.METHODS)
        self.assertEqual(calls, ['get_health', 'get_events'])


class ResponseFieldEnrichmentTest(unittest.TestCase):
    def make_parser(self) -> RPCMethodParser:
        parser = RPCMethodParser(version_info={})
        parser.parse(JSONRPC_SOURCE)
        return parser

    def test_method_without_response_file_fails_naming_it(self):
        parser = self.make_parser()

        with self.assertRaises(ValueError) as context:
            parser.add_response_fields_to_all_methods(
                {'getHealth': RESPONSE_FILES['get_health']}
            )

        message = str(context.exception)
        self.assertIn('getNetwork', message)
        self.assertNotIn('getHealth', message)

    def test_full_set_adds_fields_to_every_method(self):
        parser = self.make_parser()

        parser.add_response_fields_to_all_methods({
            'getHealth': RESPONSE_FILES['get_health'],
            'getNetwork': RESPONSE_FILES['get_network'],
        })

        def json_names(method):
            return [f['json_name'] for f in parser.methods[method]['response_fields']]

        self.assertEqual(
            json_names('getHealth'),
            ['status', 'latestLedger', 'oldestLedger', 'ledgerRetentionWindow']
        )
        self.assertEqual(
            json_names('getNetwork'),
            ['friendbotUrl', 'passphrase', 'protocolVersion']
        )

    def enrich_get_transaction(self, get_transactions_source: str) -> RPCMethodParser:
        parser = RPCMethodParser(version_info={})
        parser.methods = {'getTransaction': {}, 'getTransactions': {}}
        parser.add_response_fields_to_all_methods({
            'getTransaction': 'type GetTransactionResponse struct {\n'
                              '\tLatestLedger uint32 `json:"latestLedger"`\n'
                              '\tTransactionDetails\n'
                              '\tLedgerCloseTime int64 `json:"createdAt,string"`\n}\n',
            'getTransactions': get_transactions_source,
        })
        return parser

    def test_embedded_struct_from_another_file_adds_its_fields_in_place(self):
        parser = self.enrich_get_transaction(
            'type TransactionDetails struct {\n\tStatus string `json:"status"`\n'
            '\tTransactionHash string `json:"txHash"`\n}\n\n'
            'type GetTransactionsResponse struct {\n\tCursor string `json:"cursor"`\n}\n')
        self.assertEqual(
            [f['json_name'] for f in parser.methods['getTransaction']['response_fields']],
            ['latestLedger', 'status', 'txHash', 'createdAt'])

    def test_embedded_struct_declared_nowhere_fails_naming_it(self):
        with self.assertRaisesRegex(ValueError, 'GetTransactionResponse embeds TransactionDetails, which no fetched'):
            self.enrich_get_transaction(
                'type GetTransactionsResponse struct {\n\tCursor string `json:"cursor"`\n}\n')


class ResponseFieldComparisonTest(unittest.TestCase):
    def test_json_format_variants_are_left_out(self):
        analyzer = generate_rpc_comparison.RPCComparisonAnalyzer({'metadata': dict.fromkeys(
            ('rpc_version', 'rpc_release_date', 'rpc_release_url'), '')}, {})
        coverage = analyzer._compare_response_fields('getTransaction', [
            {'json_name': 'envelopeXdr'}, {'json_name': 'envelopeJson'}], ['envelopeXdr'])
        self.assertEqual((coverage.total, coverage.missing), (1, []))

    def test_json_format_variants_are_left_out_of_a_missing_method(self):
        analyzer = generate_rpc_comparison.RPCComparisonAnalyzer({'metadata': dict.fromkeys(
            ('rpc_version', 'rpc_release_date', 'rpc_release_url'), ''), 'methods': {'getTransaction': {
                'response_fields': [{'json_name': 'envelopeXdr'}, {'json_name': 'envelopeJson'}]}}}, {})
        analyzer.analyze()
        self.assertEqual(analyzer.comparisons[0].response_fields.missing, ['envelopeXdr'])

    def test_missing_method_shows_a_dash_for_the_flutter_method(self):
        analyzer = generate_rpc_comparison.RPCComparisonAnalyzer({'metadata': dict.fromkeys(
            ('rpc_version', 'rpc_release_date', 'rpc_release_url'), ''), 'methods': {'getHealth': {}}}, {})
        analyzer.analyze()
        with tempfile.TemporaryDirectory() as out, redirect_stdout(io.StringIO()):
            analyzer.generate_markdown_report(str(Path(out) / 'matrix.md'))
            matrix = (Path(out) / 'matrix.md').read_text(encoding='utf-8')
        self.assertIn('| `getHealth` | ❌ Not Supported | - |', matrix)


class RpcPipelineTest(FakeGitHubTestCase):
    """The RPC pipeline with network calls faked and outputs in a temporary directory."""

    def setUp(self):
        super().setUp()
        temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(temp_dir.cleanup)
        self.output_dir = Path(temp_dir.name)

    def make_pipeline(self, **kwargs) -> RPCAnalysisPipeline:
        pipeline = RPCAnalysisPipeline(**kwargs)
        pipeline.data_dir = self.output_dir
        pipeline.rpc_methods_file = self.output_dir / 'rpc_methods.json'
        pipeline.sdk_implementation_file = self.output_dir / 'flutter_soroban_implementation.json'
        pipeline.comparison_file = self.output_dir / 'rpc_comparison.json'
        pipeline.statistics_file = self.output_dir / 'rpc_coverage_stats.json'
        pipeline.markdown_file = self.output_dir / 'RPC_COMPATIBILITY_MATRIX.md'
        # The run summary lists outputs relative to the SDK root, which the
        # temporary directory is not under.
        for target, name in ((pipeline, 'collect_statistics'),
                             (pipeline.progress, 'print_summary')):
            patcher = mock.patch.object(target, name)
            patcher.start()
            self.addCleanup(patcher.stop)
        return pipeline

    def serve_upstream(
        self,
        tag: str,
        response_names: Sequence[str] = ('get_health', 'get_network')
    ) -> None:
        self.github.add(jsonrpc_url(tag), JSONRPC_SOURCE)
        self.github.add(go_mod_url(tag), GO_MOD)
        for snake_name in response_names:
            self.github.add(response_file_url(snake_name), RESPONSE_FILES[snake_name])

    def write_matrix(self, pipeline: RPCAnalysisPipeline) -> List[str]:
        with mock.patch.object(generate_rpc_comparison, 'get_sdk_version',
                               return_value='3.8.0'), \
                redirect_stdout(io.StringIO()):
            pipeline.fetch_rpc_release()
            pipeline.parse_rpc_methods()
            pipeline.analyze_flutter_sdk()
            pipeline.generate_comparison_reports()
        return pipeline.markdown_file.read_text(encoding='utf-8').splitlines()

    def run_pipeline(self, pipeline: RPCAnalysisPipeline) -> int:
        """Run the pipeline and keep its console output in self.output."""
        buffer = io.StringIO()
        with redirect_stdout(buffer):
            exit_code = pipeline.run()
        self.output = buffer.getvalue()
        return exit_code

    def test_override_header_cites_the_release_record(self):
        self.serve_releases([
            release_record('v28.0.1'),
            release_record('v27.1.1', published_at='2026-07-07T21:51:04Z'),
        ])
        self.serve_upstream('v27.1.1')

        header = self.write_matrix(self.make_pipeline(rpc_version='v27.1.1'))

        url = release_url('v27.1.1')
        self.assertEqual(header[0], '# Soroban RPC vs Flutter SDK Compatibility Matrix')
        self.assertEqual(header[2], '**RPC Version:** v27.1.1 (released 2026-07-07)  ')
        self.assertEqual(header[3], f'**RPC Source:** [{url}]({url})  ')
        self.assertEqual(header[4], '**SDK Version:** 3.8.0  ')
        self.assertRegex(header[5], r'^\*\*Generated:\*\* \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$')

    def test_record_without_published_at_prints_released_unknown(self):
        self.serve_releases([release_record('v28.0.1', published_at=None)])
        self.serve_upstream('v28.0.1')

        header = self.write_matrix(self.make_pipeline())

        self.assertEqual(header[2], '**RPC Version:** v28.0.1 (released unknown)  ')

    def test_run_with_complete_upstream_writes_the_matrix(self):
        self.serve_releases([release_record('v28.0.1')])
        self.serve_upstream('v28.0.1')
        pipeline = self.make_pipeline()

        with mock.patch.object(generate_rpc_comparison, 'get_sdk_version',
                               return_value='3.8.0'):
            self.assertEqual(self.run_pipeline(pipeline), 0)

        self.assertTrue(pipeline.markdown_file.exists())
        methods = json.loads(pipeline.rpc_methods_file.read_text(encoding='utf-8'))['methods']
        self.assertEqual(sorted(methods), ['getHealth', 'getNetwork'])
        for method_name, method in methods.items():
            with self.subTest(method=method_name):
                self.assertTrue(method['response_fields'])

    def test_run_without_a_stable_release_fails_and_writes_nothing(self):
        self.serve_releases([release_record('v29.0.0-rc.1', prerelease=True)])

        self.assertEqual(self.run_pipeline(self.make_pipeline()), 1)
        self.assertEqual(list(self.output_dir.iterdir()), [])

    def test_run_with_a_missing_response_file_fails_and_writes_nothing(self):
        self.serve_releases([release_record('v28.0.1')])
        self.serve_upstream('v28.0.1', response_names=('get_health',))

        self.assertEqual(self.run_pipeline(self.make_pipeline()), 1)
        self.assertIn(response_file_url('get_network'), self.github.requested)
        self.assertEqual(list(self.output_dir.iterdir()), [])

    def assert_unparsed_response_fails(self, get_network_source: str) -> None:
        self.serve_releases([release_record('v28.0.1')])
        self.serve_upstream('v28.0.1')
        self.github.add(response_file_url('get_network'), get_network_source)

        self.assertEqual(self.run_pipeline(self.make_pipeline()), 1)
        self.assertIn('No response fields parsed for getNetwork', self.output)
        self.assertEqual(list(self.output_dir.iterdir()), [])

    def test_run_with_a_response_file_without_a_struct_fails_and_writes_nothing(self):
        self.assert_unparsed_response_fails('package protocol\n')

    def test_run_with_a_struct_without_json_fields_fails_and_writes_nothing(self):
        self.assert_unparsed_response_fails(
            'package protocol\n\n'
            'type GetNetworkResponse struct {\n'
            '\tPassphrase string\n'
            '}\n'
        )

    def test_run_without_sdk_version_fails_and_writes_no_matrix(self):
        self.serve_releases([release_record('v28.0.1')])
        self.serve_upstream('v28.0.1')
        empty_sdk_root = tempfile.TemporaryDirectory()
        self.addCleanup(empty_sdk_root.cleanup)
        pipeline = self.make_pipeline()

        with mock.patch.object(common, 'SDK_ROOT', Path(empty_sdk_root.name)):
            exit_code = self.run_pipeline(pipeline)

        self.assertEqual(exit_code, 1)
        self.assertFalse(pipeline.markdown_file.exists())


if __name__ == '__main__':
    unittest.main()
