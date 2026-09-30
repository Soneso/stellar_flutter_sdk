"""Tests for the shared SDK version lookup and base value evaluation in common.py."""

import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

TOOLS_DIR = Path(__file__).resolve().parent.parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import common  # noqa: E402


class GetSdkVersionTest(unittest.TestCase):
    """get_sdk_version() reads pubspec.yaml under a temporary SDK root."""

    def setUp(self):
        temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(temp_dir.cleanup)
        self.sdk_root = Path(temp_dir.name)
        patcher = mock.patch.object(common, 'SDK_ROOT', self.sdk_root)
        patcher.start()
        self.addCleanup(patcher.stop)
        self.pubspec = self.sdk_root / 'pubspec.yaml'

    def test_returns_the_pubspec_version(self):
        self.pubspec.write_text(
            'name: stellar_flutter_sdk\nversion: 3.8.0\n', encoding='utf-8'
        )
        self.assertEqual(common.get_sdk_version(), '3.8.0')

    def test_missing_pubspec_raises(self):
        with self.assertRaisesRegex(RuntimeError, 'Cannot read the SDK version'):
            common.get_sdk_version()

    def test_unreadable_pubspec_raises(self):
        self.pubspec.mkdir()
        with self.assertRaisesRegex(RuntimeError, 'Cannot read the SDK version'):
            common.get_sdk_version()

    def test_undecodable_pubspec_raises(self):
        self.pubspec.write_bytes(b'version: 3.8.0\n\xff\xfe\n')
        with self.assertRaisesRegex(RuntimeError, 'Cannot read the SDK version'):
            common.get_sdk_version()

    def test_pubspec_without_version_raises(self):
        self.pubspec.write_text('name: stellar_flutter_sdk\n', encoding='utf-8')
        with self.assertRaisesRegex(RuntimeError, 'No version field'):
            common.get_sdk_version()


class EvaluateShiftExpressionTest(unittest.TestCase):
    """evaluate_shift_expression() reads the SEP-23 base value notation."""

    def test_evaluates_literals_and_left_shifts(self):
        cases = {
            '6 << 3': 48,
            '1<<3': 8,
            '  23 <<  3 ': 184,
            '48': 48,
            '0x30': 48,
            '0X0C << 3': 96,
            '1_4_4': 144,
            '0x6_0': 96,
            '1_2 << 3': 96,
        }
        for expression, value in cases.items():
            with self.subTest(expression=expression):
                self.assertEqual(common.evaluate_shift_expression(expression), value)

    def test_other_forms_raise(self):
        for expression in ('', 'six << 3', '6 >> 3', '6 <<< 3', '6 << ', '-6 << 3',
                           '6 << 3;', 'SEED_BASE << 3', '6 << 0x3', '144_', '_144', '0x_60'):
            with self.subTest(expression=expression):
                with self.assertRaisesRegex(ValueError, 'Not an integer or shift expression'):
                    common.evaluate_shift_expression(expression)


if __name__ == '__main__':
    unittest.main()
