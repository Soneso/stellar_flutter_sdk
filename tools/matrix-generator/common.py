#!/usr/bin/env python3
"""
Shared utilities for the compatibility matrix generator.
"""

import re
import sys
import time
from pathlib import Path
from typing import Any, Dict

# Root directories resolved from this file's location
TOOLS_DIR = Path(__file__).parent
SDK_ROOT = TOOLS_DIR.parent.parent
DATA_DIR = TOOLS_DIR / 'data'
COMPATIBILITY_DIR = SDK_ROOT / 'compatibility'


class Colors:
    """ANSI color codes for terminal output"""
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

    @classmethod
    def disable(cls):
        """Disable colors (for non-TTY output)"""
        for attr in ('HEADER', 'BLUE', 'CYAN', 'GREEN', 'YELLOW',
                      'RED', 'BOLD', 'UNDERLINE', 'END'):
            setattr(cls, attr, '')


def get_sdk_version() -> str:
    """
    Extract SDK version from pubspec.yaml.

    Every matrix header prints this value, so a pubspec.yaml that is missing,
    unreadable, or without a version field raises.

    Returns:
        Version string (e.g. '3.0.3').

    Raises:
        RuntimeError: If pubspec.yaml cannot be read or carries no version.
    """
    pubspec_path = SDK_ROOT / 'pubspec.yaml'
    try:
        content = pubspec_path.read_text(encoding='utf-8')
    except (OSError, UnicodeDecodeError) as e:
        raise RuntimeError(
            f"Cannot read the SDK version from {pubspec_path}: {e}"
        ) from e
    match = re.search(r'version:\s*([0-9.]+)', content)
    if not match:
        raise RuntimeError(f"No version field in {pubspec_path}")
    return match.group(1)


# Decimal or hexadecimal digits, with Dart's '_' separators between digits.
_DECIMAL = r'[0-9](?:_*[0-9])*'
_SHIFT_EXPRESSION = re.compile(
    rf'\s*(0[xX][0-9a-fA-F](?:_*[0-9a-fA-F])*|{_DECIMAL})\s*(?:<<\s*({_DECIMAL})\s*)?'
)


def evaluate_shift_expression(expression: str) -> int:
    """
    Evaluate a decimal or hexadecimal literal, or a left shift of one by a
    decimal count, such as '6 << 3'; '_' may separate digits. SEP-23 prints
    its base values this way and the SDK declares its version bytes the same
    way.

    Raises:
        ValueError: If the expression has any other form.
    """
    match = _SHIFT_EXPRESSION.fullmatch(expression)
    if not match:
        raise ValueError(f"Not an integer or shift expression: {expression!r}")
    literal, shift = (group.replace('_', '') if group else group for group in match.groups())
    value = int(literal, 16) if literal[:2].lower() == '0x' else int(literal)
    return value << int(shift) if shift is not None else value


class ProgressTracker:
    """Track and display progress of pipeline steps."""

    def __init__(self, total_steps: int = 4, verbose: bool = False):
        self.verbose = verbose
        self.step = 0
        self.total_steps = total_steps
        self.start_time = time.time()
        self.step_times: Dict[int, float] = {}

    def start_step(self, description: str) -> None:
        """Start a new step and print progress."""
        self.step += 1
        self.step_times[self.step] = time.time()
        print()
        print(f"Step {self.step}/{self.total_steps}: {description}")
        print("-" * 60)

    def finish_step(self, message: str = "") -> None:
        """Finish current step and print timing."""
        if self.step in self.step_times:
            elapsed = time.time() - self.step_times[self.step]
            if message:
                print(f"  {message}")
            if self.verbose:
                print(f"  Completed in {elapsed:.2f}s")

    def log(self, message: str, force: bool = False) -> None:
        """Log a message (only in verbose mode unless forced)."""
        if self.verbose or force:
            print(f"  {message}")

    def print_summary(self, stats: Dict[str, Any]) -> None:
        """Print final summary with coverage stats."""
        total_time = time.time() - self.start_time

        # Determine label/count keys from stats
        api_version_key = next(
            (k for k in ('horizon_version', 'rpc_version') if k in stats), None
        )
        total_key = next(
            (k for k in ('total_endpoints', 'total_methods') if k in stats), None
        )
        item_label = 'endpoints' if 'total_endpoints' in stats else 'methods'

        print()
        print("=" * 60)
        print("Analysis Complete!")
        print("=" * 60)
        print()
        if api_version_key:
            print(f"{api_version_key.replace('_', ' ').title()}: {stats[api_version_key]}")
        print(f"SDK Version: {stats.get('sdk_version', 'Unknown')}")
        if total_key:
            print(f"Coverage: {stats['coverage_percentage']}% "
                  f"({stats['fully_supported']}/{stats[total_key]} {item_label})")
        print()
        print("Generated files:")
        for file_path in stats.get('generated_files', []):
            print(f"  - {file_path}")
        print()
        print(f"Total time: {total_time:.2f}s")
        print("=" * 60)
