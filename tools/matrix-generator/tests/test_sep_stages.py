"""Tests for the SEP number dispatch of the SEP stages and the SDK references they print."""

import io
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent.parent
for path in (TOOLS_DIR, TOOLS_DIR / 'sep'):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

from generate_sep_comparison import SEPComparator  # noqa: E402
from sep_analyzer import SEPAnalyzer  # noqa: E402
from sep_parser import SEPParser  # noqa: E402


class SepStagesTest(unittest.TestCase):
    def test_every_stage_stops_for_a_sep_number_without_code(self):
        parser = SEPParser('0031')
        parser.raw_content = '# SEP-0031\n'
        comparator = SEPComparator('definition.json', 'analysis.json', '0031')
        comparator.sdk_data = {'implemented': True}
        for stage in (parser.parse, SEPAnalyzer(str(TOOLS_DIR), '0031').analyze, comparator.compare_fields):
            with self.subTest(stage=stage.__qualname__), redirect_stdout(io.StringIO()), \
                    self.assertRaisesRegex(ValueError, 'defined for SEP-0031'):
                stage()

    def test_analysis_stops_without_a_definition_file(self):
        analyzer = SEPAnalyzer(str(TOOLS_DIR.parent.parent), '0002')
        with tempfile.TemporaryDirectory() as data_dir, redirect_stdout(io.StringIO()):
            analyzer.data_dir = Path(data_dir)
            with self.assertRaises(FileNotFoundError):
                analyzer.analyze()

    def test_sep_06_status_values_cite_the_status_property(self):
        comparator = SEPComparator('definition.json', 'analysis.json', '0006')
        comparator.sdk_data = {'implemented': True, 'implemented_features': {'transaction_status_values': {
            'completed': {'required': True, 'implemented': True, 'sdk_property': 'status'}}}}
        with redirect_stdout(io.StringIO()):
            comparator.compare_fields()
        self.assertEqual([c.sdk_property for c in comparator.comparisons], ['status'])


if __name__ == '__main__':
    unittest.main()
