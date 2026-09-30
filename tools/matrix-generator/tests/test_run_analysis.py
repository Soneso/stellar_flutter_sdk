"""Tests for the step sequence of run_analysis.py.

Every script invocation goes to a fake subprocess.run; no generator runs.
"""

import io
import json
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from typing import List
from unittest import mock

TOOLS_DIR = Path(__file__).resolve().parent.parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import run_analysis  # noqa: E402

STALE_PREAMBLE = {
    'title': 'Sign and Verify Messages',
    'version': '0.0.1',
    'status': 'Final Comment Period (Final)',
}

MATRIX = (
    b'# SEP-NNNN Compatibility Matrix\n\n'
    b'**Generated:** 2026-09-28 01:09:56  \n'
    b'**SEP Version:** 1.0.0  \n'
)


class FailedStageStopsTheRunTest(unittest.TestCase):
    """A failed SEP parser stage leaves the cached definition's matrix untouched."""

    def run_with_failing_parser(self, sep_number: str) -> tuple:
        """
        Run main() with every step faked and the parser of one SEP failing.

        The fake comparator of that SEP writes the matrix from the cached
        definition, as the real comparator does.

        Returns:
            (exit code, invoked steps, matrix bytes before, matrix bytes after)
        """
        temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(temp_dir.cleanup)
        definition = Path(temp_dir.name) / f'sep_{sep_number}_definition.json'
        definition.write_text(json.dumps({'preamble': STALE_PREAMBLE}), encoding='utf-8')
        matrix = Path(temp_dir.name) / f'SEP-{sep_number}_COMPATIBILITY_MATRIX.md'
        matrix.write_bytes(MATRIX)
        matrix_before = matrix.read_bytes()

        tools_dir = Path(run_analysis.__file__).parent
        invoked: List[str] = []

        def fake_run(command, **kwargs):
            step = ' '.join(
                [Path(command[1]).relative_to(tools_dir).as_posix()] + command[2:]
            )
            invoked.append(step)
            if step == f'sep/sep_parser.py {sep_number}':
                return subprocess.CompletedProcess(command, 1, stdout='', stderr='HTTP Error 503')
            if step == f'sep/generate_sep_comparison.py {sep_number}':
                preamble = json.loads(definition.read_text(encoding='utf-8'))['preamble']
                matrix.write_text(f"**SEP Version:** {preamble['version']}  \n", encoding='utf-8')
            return subprocess.CompletedProcess(command, 0, stdout='', stderr='')

        with mock.patch.object(run_analysis.subprocess, 'run', side_effect=fake_run), \
                mock.patch.object(run_analysis.AnalysisOrchestrator, 'verify_prerequisites',
                                  return_value=(True, [])), \
                mock.patch.object(run_analysis.Colors, 'disable'), \
                redirect_stdout(io.StringIO()):
            exit_code = run_analysis.main()

        return exit_code, invoked, matrix_before, matrix.read_bytes()

    def test_failed_parser_stage_stops_the_run(self):
        all_steps = [script for script, _, _ in run_analysis.AnalysisOrchestrator().scripts]

        for sep_number in ('0029', '0053'):
            with self.subTest(sep=sep_number):
                exit_code, invoked, matrix_before, matrix_after = (
                    self.run_with_failing_parser(sep_number)
                )

                failed_step = f'sep/sep_parser.py {sep_number}'
                self.assertEqual(exit_code, 1)
                self.assertEqual(invoked, all_steps[:all_steps.index(failed_step) + 1])
                self.assertNotIn(f'sep/sep_analyzer.py {sep_number}', invoked)
                self.assertNotIn(f'sep/generate_sep_comparison.py {sep_number}', invoked)
                self.assertEqual(matrix_after, matrix_before)


if __name__ == '__main__':
    unittest.main()
