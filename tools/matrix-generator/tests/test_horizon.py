"""Tests for the Horizon release a matrix header cites."""

import io
import json
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path

TESTS_DIR = Path(__file__).resolve().parent
for path in (TESTS_DIR.parent, TESTS_DIR.parent / 'horizon', TESTS_DIR):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

from run_horizon_analysis import HorizonAnalysisPipeline  # noqa: E402
from test_rpc import FakeGitHubTestCase  # noqa: E402

RELEASE_URL = 'https://github.com/stellar/stellar-horizon/releases/tag/v28.0.1'


class HorizonReleaseTest(FakeGitHubTestCase):
    def test_override_takes_date_and_url_from_the_release_record(self):
        self.github.add(
            'https://api.github.com/repos/stellar/stellar-horizon/releases/tags/v28.0.1',
            json.dumps({'tag_name': 'v28.0.1', 'published_at': '2026-07-01T10:00:00Z',
                        'html_url': RELEASE_URL}))
        self.github.add('https://raw.githubusercontent.com/stellar/stellar-horizon/v28.0.1'
                        '/internal/httpx/router.go', 'package httpx\n')
        pipeline = HorizonAnalysisPipeline(horizon_version='v28.0.1')
        with redirect_stdout(io.StringIO()):
            pipeline.fetch_horizon_release()
        self.assertEqual((pipeline.release_info['published_at'], pipeline.release_info['html_url']),
                         ('2026-07-01', RELEASE_URL))


if __name__ == '__main__':
    unittest.main()
