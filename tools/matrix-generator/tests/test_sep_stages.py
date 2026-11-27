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

    def test_every_source_detection_matches_repository_source(self):
        root = TOOLS_DIR.parent.parent
        detections = SEPAnalyzer.sep_51_detections()
        sources = {
            path: (root / path).read_text(encoding='utf-8')
            for path, _, _ in detections.values()
        }
        with redirect_stdout(io.StringIO()):
            definition = SEPParser('0051').parse_sep_51()
        features = SEPAnalyzer(str(root), '0051').map_sep_51_features(sources, definition)
        entries = {name: entry for section in features.values() for name, entry in section.items()}
        self.assertEqual(set(entries), set(detections))
        for name, entry in entries.items():
            with self.subTest(feature=name):
                self.assertTrue(entry['implemented'], detections[name])

        for number, paths, count in ((29, ('stellar_sdk', 'manage_data_operation'), 18),
                                     (53, ('key_pair',), 8)):
            with redirect_stdout(io.StringIO()):
                definition = getattr(SEPParser(f'{number:04d}'), f'parse_sep_{number}')()
            contents = [(root / f'lib/src/{path}.dart').read_text(encoding='utf-8') for path in paths]
            analyzer = SEPAnalyzer(str(root), f'{number:04d}')
            features = getattr(analyzer, f'map_sep_{number}_features')(*contents, definition)
            entries = {name: entry for section in features.values() for name, entry in section.items()}
            self.assertEqual(len(entries), count)
            for name, entry in entries.items():
                with self.subTest(sep=number, feature=name):
                    self.assertTrue(entry['implemented'], name)

    def test_sep_51_fixed_opaque_detection_allows_trailing_arguments(self):
        root = TOOLS_DIR.parent.parent
        path = 'lib/src/xdr/xdr_hash.dart'
        content = (
            "XdrJsonHelper.hex(_hash, type: 'XdrHash', expectedLength: 32)\n"
            "XdrJsonHelper.readHex(value, type: 'XdrHash', expectedLength: 32)"
        )
        with redirect_stdout(io.StringIO()):
            definition = SEPParser('0051').parse_sep_51()
        analyzer = SEPAnalyzer(str(root), '0051')
        for call in ("hex(_hash", "readHex(value"):
            with self.subTest(call=call):
                original = f"XdrJsonHelper.{call}, type: 'XdrHash', expectedLength: 32)"
                sources = {path: content.replace(original, original[:-1] + ', extra: true)')}
                features = analyzer.map_sep_51_features(sources, definition)
                self.assertTrue(features['xdr_data_types']['opaque_fixed']['implemented'])

    def test_sep_06_status_values_cite_the_status_property(self):
        comparator = SEPComparator('definition.json', 'analysis.json', '0006')
        comparator.sdk_data = {'implemented': True, 'implemented_features': {'transaction_status_values': {
            'completed': {'required': True, 'implemented': True, 'sdk_property': 'status'}}}}
        with redirect_stdout(io.StringIO()):
            comparator.compare_fields()
        self.assertEqual([c.sdk_property for c in comparator.comparisons], ['status'])


if __name__ == '__main__':
    unittest.main()
