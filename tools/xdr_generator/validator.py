"""
Multi-Layer Validation

Validates generated XDR code through multiple layers:
1. Structural validation - verify all classes have required methods
2. Compilation validation - run dart analyze
3. Round-trip validation - test encode/decode cycles
4. Existing tests validation - run SDK test suite
"""

from dataclasses import dataclass, field
from typing import Dict, List, Tuple, Optional
from pathlib import Path
import subprocess
import re
import tempfile
import shutil


@dataclass
class ValidationResult:
    """Result of a validation operation."""
    passed: bool
    errors: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)

    def add_error(self, error: str):
        """Add an error and mark as failed."""
        self.errors.append(error)
        self.passed = False

    def add_warning(self, warning: str):
        """Add a warning (doesn't affect passed status)."""
        self.warnings.append(warning)

    def merge(self, other: 'ValidationResult'):
        """Merge another result into this one."""
        if not other.passed:
            self.passed = False
        self.errors.extend(other.errors)
        self.warnings.extend(other.warnings)

    def __str__(self) -> str:
        """Format validation result as string."""
        status = "PASSED" if self.passed else "FAILED"
        lines = [f"Validation {status}"]

        if self.errors:
            lines.append(f"\nErrors ({len(self.errors)}):")
            for i, error in enumerate(self.errors, 1):
                lines.append(f"  {i}. {error}")

        if self.warnings:
            lines.append(f"\nWarnings ({len(self.warnings)}):")
            for i, warning in enumerate(self.warnings, 1):
                lines.append(f"  {i}. {warning}")

        return '\n'.join(lines)


class Validator:
    """Multi-layer validator for generated XDR code."""

    def __init__(self, sdk_path: str):
        """
        Initialize validator.

        Args:
            sdk_path: Path to the SDK root directory
        """
        self.sdk_path = Path(sdk_path)
        if not self.sdk_path.exists():
            raise ValueError(f"SDK path does not exist: {sdk_path}")

    def validate_structural(
        self, generated_files: Dict[str, str]
    ) -> ValidationResult:
        """
        Layer 1: Verify all classes have required encode/decode methods.

        Args:
            generated_files: Dict mapping filenames to file contents

        Returns:
            ValidationResult with structural validation results
        """
        result = ValidationResult(passed=True)

        for filename, content in generated_files.items():
            # Extract all class names (handle extends, with, implements)
            class_pattern = r'class\s+(\w+)[^{]*\{'
            classes = re.findall(class_pattern, content)

            for class_name in classes:
                # Check if abstract class (skip validation)
                abstract_pattern = r'abstract\s+class\s+' + re.escape(class_name)
                if re.search(abstract_pattern, content):
                    continue  # Skip abstract classes

                # Verify encode method exists (allow both void and implicit void)
                # Also allow nullable parameter type (ClassName?)
                encode_pattern = (
                    rf'static\s+(?:void\s+)?encode\s*\(\s*XdrDataOutputStream\s+stream\s*,\s*'
                    rf'{re.escape(class_name)}\??\s+'
                )
                if not re.search(encode_pattern, content):
                    result.add_error(
                        f"{filename}: Class {class_name} missing encode() method"
                    )

                # Verify decode method exists
                decode_pattern = (
                    rf'static\s+{re.escape(class_name)}\s+decode\s*\(\s*'
                    rf'XdrDataInputStream\s+stream\s*\)'
                )
                if not re.search(decode_pattern, content):
                    result.add_error(
                        f"{filename}: Class {class_name} missing decode() method"
                    )

        return result

    def validate_compilation(
        self, output_dir: str, verbose: bool = False
    ) -> ValidationResult:
        """
        Layer 2: Run dart analyze on generated files.

        Args:
            output_dir: Directory containing generated files
            verbose: Enable verbose output

        Returns:
            ValidationResult with compilation validation results
        """
        result = ValidationResult(passed=True)

        output_path = Path(output_dir)
        if not output_path.exists():
            result.add_error(f"Output directory does not exist: {output_dir}")
            return result

        try:
            # Run dart analyze on the output directory
            cmd = ['dart', 'analyze', str(output_path)]

            if verbose:
                print(f"Running: {' '.join(cmd)}")

            process = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=120  # 2 minute timeout
            )

            # Parse output for errors
            if process.returncode != 0:
                result.add_error(
                    f"dart analyze failed with exit code {process.returncode}"
                )

                # Parse stderr for specific errors
                if process.stderr:
                    for line in process.stderr.split('\n'):
                        if line.strip() and 'error' in line.lower():
                            result.add_error(line.strip())

                # Parse stdout for analysis errors
                if process.stdout:
                    for line in process.stdout.split('\n'):
                        if line.strip() and 'error' in line.lower():
                            result.add_error(line.strip())
                        elif line.strip() and ('warning' in line.lower() or 'info' in line.lower()):
                            result.add_warning(line.strip())

            if verbose and process.stdout:
                print("Analyzer output:")
                print(process.stdout)

        except subprocess.TimeoutExpired:
            result.add_error("dart analyze timed out after 2 minutes")
        except FileNotFoundError:
            result.add_error(
                "dart command not found. Ensure Dart SDK is installed and in PATH"
            )
        except Exception as e:
            result.add_error(f"Unexpected error running dart analyze: {e}")

        return result

    def validate_round_trip(
        self, generated_files: Dict[str, str], verbose: bool = False
    ) -> ValidationResult:
        """
        Layer 3: Test encode->decode round-trip (requires Dart test runner).

        This generates simple test cases for each XDR type and runs them.

        Args:
            generated_files: Dict mapping filenames to file contents
            verbose: Enable verbose output

        Returns:
            ValidationResult with round-trip test results
        """
        result = ValidationResult(passed=True)

        # For now, this is a placeholder that would require:
        # 1. Generating test cases for each XDR type
        # 2. Creating temporary Dart test file
        # 3. Running dart test
        # This is complex and would be implemented later

        result.add_warning(
            "Round-trip validation not yet implemented - requires test generation"
        )

        return result

    def validate_existing_tests(self, verbose: bool = False) -> ValidationResult:
        """
        Layer 4: Run existing SDK test suite.

        Args:
            verbose: Enable verbose output

        Returns:
            ValidationResult with test suite results
        """
        result = ValidationResult(passed=True)

        try:
            # Run dart test in the SDK directory
            cmd = ['dart', 'test']

            if verbose:
                print(f"Running: {' '.join(cmd)} in {self.sdk_path}")

            process = subprocess.run(
                cmd,
                cwd=str(self.sdk_path),
                capture_output=True,
                text=True,
                timeout=600  # 10 minute timeout for tests
            )

            # Check if tests passed
            if process.returncode != 0:
                result.add_error(
                    f"Test suite failed with exit code {process.returncode}"
                )

                # Parse output for failed tests
                if process.stdout:
                    # Look for test failure patterns
                    failure_pattern = r'(\d+)\s+(?:test|tests)\s+(?:failed|failing)'
                    match = re.search(failure_pattern, process.stdout, re.IGNORECASE)
                    if match:
                        result.add_error(f"{match.group(1)} tests failed")

                    # Extract failed test names
                    test_fail_pattern = r'(✗|FAILED|Error:)\s+(.+)'
                    for line in process.stdout.split('\n'):
                        match = re.search(test_fail_pattern, line)
                        if match:
                            result.add_error(f"Failed test: {match.group(2).strip()}")

            else:
                # Tests passed, extract summary
                if process.stdout:
                    # Look for test count
                    count_pattern = r'(\d+)\s+(?:test|tests)\s+passed'
                    match = re.search(count_pattern, process.stdout, re.IGNORECASE)
                    if match and verbose:
                        print(f"All {match.group(1)} tests passed")

            if verbose and process.stdout:
                print("Test output:")
                print(process.stdout)

        except subprocess.TimeoutExpired:
            result.add_error("Test suite timed out after 10 minutes")
        except FileNotFoundError:
            result.add_error(
                "dart command not found. Ensure Dart SDK is installed and in PATH"
            )
        except Exception as e:
            result.add_error(f"Unexpected error running tests: {e}")

        return result

    def run_all_validations(
        self,
        generated_files: Dict[str, str],
        output_dir: str,
        skip_tests: bool = False,
        verbose: bool = False
    ) -> ValidationResult:
        """
        Run all validation layers.

        Args:
            generated_files: Dict mapping filenames to generated content
            output_dir: Directory containing generated files
            skip_tests: Skip test suite validation (faster)
            verbose: Enable verbose output

        Returns:
            Combined ValidationResult from all layers
        """
        combined_result = ValidationResult(passed=True)

        # Layer 1: Structural validation
        if verbose:
            print("\n=== Layer 1: Structural Validation ===")

        structural = self.validate_structural(generated_files)
        combined_result.merge(structural)

        if verbose:
            print(f"Structural validation: {'PASSED' if structural.passed else 'FAILED'}")
            if structural.errors:
                print(f"  Errors: {len(structural.errors)}")
            if structural.warnings:
                print(f"  Warnings: {len(structural.warnings)}")

        # Layer 2: Compilation validation
        if verbose:
            print("\n=== Layer 2: Compilation Validation ===")

        compilation = self.validate_compilation(output_dir, verbose=verbose)
        combined_result.merge(compilation)

        if verbose:
            print(f"Compilation validation: {'PASSED' if compilation.passed else 'FAILED'}")
            if compilation.errors:
                print(f"  Errors: {len(compilation.errors)}")

        # Layer 3: Round-trip validation (placeholder)
        if verbose:
            print("\n=== Layer 3: Round-trip Validation ===")

        round_trip = self.validate_round_trip(generated_files, verbose=verbose)
        combined_result.merge(round_trip)

        if verbose:
            print(f"Round-trip validation: {'PASSED' if round_trip.passed else 'FAILED'}")
            if round_trip.warnings:
                print(f"  Warnings: {len(round_trip.warnings)}")

        # Layer 4: Existing tests (optional, can be slow)
        if not skip_tests:
            if verbose:
                print("\n=== Layer 4: Test Suite Validation ===")

            test_result = self.validate_existing_tests(verbose=verbose)
            combined_result.merge(test_result)

            if verbose:
                print(f"Test suite validation: {'PASSED' if test_result.passed else 'FAILED'}")
        elif verbose:
            print("\n=== Layer 4: Test Suite Validation ===")
            print("Skipped (--skip-tests flag)")

        return combined_result


def validate_files_in_temp_dir(
    generated_files: Dict[str, str],
    sdk_path: str,
    skip_tests: bool = False,
    verbose: bool = False
) -> Tuple[ValidationResult, Optional[str]]:
    """
    Validate generated files in a temporary directory.

    Creates a temporary directory, copies files, and runs validation.
    Useful for testing without modifying the actual SDK.

    Args:
        generated_files: Dict mapping filenames to file contents
        sdk_path: Path to SDK root directory
        skip_tests: Skip test suite validation
        verbose: Enable verbose output

    Returns:
        Tuple of (ValidationResult, temp_dir_path)
        temp_dir_path is None if validation failed to create temp dir

    Example:
        >>> result, temp_dir = validate_files_in_temp_dir(
        ...     {'xdr_memo.dart': '...'},
        ...     '/path/to/sdk'
        ... )
        >>> print(result)
    """
    temp_dir = None

    try:
        # Create temporary directory
        temp_dir = tempfile.mkdtemp(prefix='xdr_validation_')
        temp_path = Path(temp_dir)

        if verbose:
            print(f"Created temporary validation directory: {temp_dir}")

        # Write generated files to temp directory
        for filename, content in generated_files.items():
            file_path = temp_path / filename
            file_path.write_text(content, encoding='utf-8')

        # Run validation
        validator = Validator(sdk_path)
        result = validator.run_all_validations(
            generated_files,
            str(temp_path),
            skip_tests=skip_tests,
            verbose=verbose
        )

        return result, temp_dir

    except Exception as e:
        result = ValidationResult(passed=False)
        result.add_error(f"Failed to create validation environment: {e}")
        return result, None
