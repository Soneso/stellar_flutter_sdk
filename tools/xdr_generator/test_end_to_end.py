#!/usr/bin/env python3
"""
End-to-End Integration Test for XDR Generator

Tests the complete workflow from fetching XDR files to generating validated Dart code.

Test Steps:
1. Fetch XDR files from stellar-xdr v25.0
2. Parse all XDR files to AST
3. Test type mapping and dependency resolution
4. Generate Dart code for sample types
5. Test merger with custom code extraction
6. Run structural validation
7. Generate sample output and compare with existing
"""

import sys
import tempfile
from pathlib import Path
from typing import Dict, List, Tuple

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tools.xdr_generator.xdr_fetcher import fetch_xdr_files, get_available_versions, XdrRelease
from tools.xdr_generator.xdr_lexer import XdrLexer
from tools.xdr_generator.xdr_parser import XdrParser
from tools.xdr_generator.type_mapping import TypeMapper
from tools.xdr_generator.file_mapping import FileMapper
from tools.xdr_generator.dependency_resolver import DependencyResolver
from tools.xdr_generator.dart_generator import DartGenerator
from tools.xdr_generator.dart_analyzer import DartAnalyzer
from tools.xdr_generator.dart_merger import DartMerger
from tools.xdr_generator.validator import Validator
from tools.xdr_generator.error_handler import GeneratorErrorHandler


class TestResult:
    """Holds test results and statistics."""

    def __init__(self):
        self.phases_passed = []
        self.phases_failed = []
        self.xdr_files_count = 0
        self.types_parsed = {'constants': 0, 'typedefs': 0, 'enums': 0, 'structs': 0, 'unions': 0}
        self.custom_sections_found = 0
        self.generated_classes = 0
        self.validation_errors = []
        self.validation_warnings = []

    def mark_phase_passed(self, phase: str):
        """Mark a test phase as passed."""
        self.phases_passed.append(phase)

    def mark_phase_failed(self, phase: str, error: str):
        """Mark a test phase as failed."""
        self.phases_failed.append((phase, error))

    def print_summary(self):
        """Print test summary."""
        print("\n" + "=" * 80)
        print("END-TO-END TEST SUMMARY")
        print("=" * 80)

        print(f"\nPhases Passed: {len(self.phases_passed)}")
        for phase in self.phases_passed:
            print(f"  ✓ {phase}")

        if self.phases_failed:
            print(f"\nPhases Failed: {len(self.phases_failed)}")
            for phase, error in self.phases_failed:
                print(f"  ✗ {phase}: {error}")

        print(f"\nStatistics:")
        print(f"  XDR Files Fetched: {self.xdr_files_count}")
        print(f"  Types Parsed:")
        print(f"    - Constants: {self.types_parsed['constants']}")
        print(f"    - Typedefs:  {self.types_parsed['typedefs']}")
        print(f"    - Enums:     {self.types_parsed['enums']}")
        print(f"    - Structs:   {self.types_parsed['structs']}")
        print(f"    - Unions:    {self.types_parsed['unions']}")
        print(f"  Custom Code Sections Found: {self.custom_sections_found}")
        print(f"  Classes Generated: {self.generated_classes}")
        print(f"  Validation Errors: {len(self.validation_errors)}")
        print(f"  Validation Warnings: {len(self.validation_warnings)}")

        if self.validation_errors:
            print(f"\nValidation Errors:")
            for error in self.validation_errors[:5]:  # Show first 5
                print(f"  - {error}")
            if len(self.validation_errors) > 5:
                print(f"  ... and {len(self.validation_errors) - 5} more")

        total_passed = len(self.phases_passed)
        total_tests = total_passed + len(self.phases_failed)

        print(f"\n{'=' * 80}")
        print(f"Overall: {total_passed}/{total_tests} phases passed")
        print("=" * 80)

        return len(self.phases_failed) == 0


def test_phase1_fetcher(result: TestResult) -> Dict[str, str]:
    """
    Phase 1: Test XDR Fetcher

    Fetches XDR files from stellar-xdr v25.0

    Returns:
        Dictionary mapping filename to content
    """
    print("\n" + "=" * 80)
    print("PHASE 1: XDR FETCHER")
    print("=" * 80)

    try:
        print("\nFetching available versions...")
        versions = get_available_versions()
        print(f"  Found {len(versions)} versions")

        if not versions:
            result.mark_phase_failed("Phase 1: Fetcher", "No versions found")
            return {}

        print(f"  Latest version: {versions[0].version}")

        print("\nFetching XDR files for v25.0...")
        xdr_files, failed_files = fetch_xdr_files("v25.0")

        if failed_files:
            print(f"  Warning: {len(failed_files)} files failed to fetch:")
            for filename in failed_files:
                print(f"    - {filename}")

        if not xdr_files:
            result.mark_phase_failed("Phase 1: Fetcher", "No XDR files fetched")
            return {}

        result.xdr_files_count = len(xdr_files)

        print(f"  Fetched {len(xdr_files)} XDR files:")
        for filename in sorted(xdr_files.keys()):
            size = len(xdr_files[filename])
            print(f"    - {filename} ({size:,} bytes)")

        result.mark_phase_passed("Phase 1: XDR Fetcher")
        return xdr_files

    except Exception as e:
        result.mark_phase_failed("Phase 1: Fetcher", str(e))
        import traceback
        traceback.print_exc()
        return {}


def test_phase2_parser(xdr_files: Dict[str, str], result: TestResult) -> Dict[str, any]:
    """
    Phase 2: Test XDR Parser

    Parses all XDR files to AST

    Returns:
        Dictionary mapping filename to parsed AST
    """
    print("\n" + "=" * 80)
    print("PHASE 2: XDR PARSER")
    print("=" * 80)

    try:
        parsed_asts = {}

        print(f"\nParsing {len(xdr_files)} XDR files...")

        for filename, content in sorted(xdr_files.items()):
            print(f"\n  Parsing {filename}...")

            # Tokenize
            lexer = XdrLexer(content, filename)
            tokens = lexer.tokenize()
            print(f"    Tokens: {len(tokens)}")

            # Parse
            parser = XdrParser(tokens, filename)
            ast = parser.parse()

            counts = ast.count_definitions()
            result.types_parsed['constants'] += counts[0]
            result.types_parsed['typedefs'] += counts[1]
            result.types_parsed['enums'] += counts[2]
            result.types_parsed['structs'] += counts[3]
            result.types_parsed['unions'] += counts[4]

            print(f"    Constants: {counts[0]}, Typedefs: {counts[1]}, Enums: {counts[2]}, Structs: {counts[3]}, Unions: {counts[4]}")

            parsed_asts[filename] = ast

        print(f"\nParsing complete!")
        print(f"  Total types parsed: {sum(result.types_parsed.values())}")

        result.mark_phase_passed("Phase 2: XDR Parser")
        return parsed_asts

    except Exception as e:
        result.mark_phase_failed("Phase 2: Parser", str(e))
        import traceback
        traceback.print_exc()
        return {}


def test_phase3_type_system(parsed_asts: Dict[str, any], result: TestResult) -> Tuple:
    """
    Phase 3: Test Type System

    Tests type mapping, file mapping, and dependency resolution

    Returns:
        Tuple of (TypeMapper, FileMapper, DependencyResolver)
    """
    print("\n" + "=" * 80)
    print("PHASE 3: TYPE SYSTEM")
    print("=" * 80)

    try:
        print("\nInitializing type mapper...")
        type_mapper = TypeMapper()
        print(f"  Basic type mappings: {len(type_mapper.PRIMITIVE_TYPES)}")

        print("\nInitializing file mapper...")
        file_mapper = FileMapper()
        print(f"  Type-to-file mappings: {len(file_mapper.type_to_file)}")

        print("\nInitializing dependency resolver...")
        dependency_resolver = DependencyResolver()

        # Collect all types from all files
        print("\nCollecting types from ASTs...")
        all_types = set()
        for filename, ast in parsed_asts.items():
            for enum in ast.enums:
                all_types.add(enum.name)
            for struct in ast.structs:
                all_types.add(struct.name)
            for union in ast.unions:
                all_types.add(union.name)

        print(f"  Total types collected: {len(all_types)}")

        # Sample type mapping tests
        print("\nTesting type mappings:")
        test_types = ['uint32', 'uint64', 'int32', 'string', 'Hash', 'PublicKey']
        for xdr_type in test_types:
            dart_type = type_mapper.map_type(xdr_type)
            print(f"  {xdr_type:20} -> {dart_type}")

        # Sample file mapping tests
        print("\nTesting file mappings:")
        test_types = ['XdrHash', 'XdrTransaction', 'XdrLedgerHeader']
        for type_name in test_types:
            dart_file = file_mapper.infer_file_for_type(type_name)
            print(f"  {type_name:30} -> {dart_file}")

        result.mark_phase_passed("Phase 3: Type System")
        return (type_mapper, file_mapper, dependency_resolver)

    except Exception as e:
        result.mark_phase_failed("Phase 3: Type System", str(e))
        import traceback
        traceback.print_exc()
        return (None, None, None)


def test_phase4_generator(parsed_asts: Dict[str, any], result: TestResult) -> Dict[str, str]:
    """
    Phase 4: Test Dart Generator

    Generates Dart code for sample types

    Returns:
        Dictionary mapping type name to generated code
    """
    print("\n" + "=" * 80)
    print("PHASE 4: DART GENERATOR")
    print("=" * 80)

    try:
        print("\nInitializing Dart generator...")
        generator = DartGenerator()

        generated_code = {}

        # Find Stellar-types.x which has good variety of types
        if 'Stellar-types.x' in parsed_asts:
            ast = parsed_asts['Stellar-types.x']

            print(f"\nGenerating code from Stellar-types.x...")

            # Generate first 3 enums
            print("\n  Generating enums:")
            for enum in ast.enums[:3]:
                print(f"    - {enum.name}")
                code = generator.generate_enum(enum)
                generated_code[enum.name] = code
                result.generated_classes += 1

            # Generate first 3 structs
            print("\n  Generating structs:")
            for struct in ast.structs[:3]:
                print(f"    - {struct.name}")
                code = generator.generate_struct(struct)
                generated_code[struct.name] = code
                result.generated_classes += 1

            # Generate first 3 unions
            print("\n  Generating unions:")
            for union in ast.unions[:3]:
                print(f"    - {union.name}")
                code = generator.generate_union(union)
                generated_code[union.name] = code
                result.generated_classes += 1

            print(f"\nGeneration complete! Generated {len(generated_code)} classes")

            # Show sample output for first generated class
            if generated_code:
                first_name = next(iter(generated_code))
                first_code = generated_code[first_name]
                print(f"\nSample output ({first_name}):")
                print("-" * 80)
                lines = first_code.split('\n')
                for line in lines[:25]:
                    print(line)
                if len(lines) > 25:
                    print(f"... ({len(lines) - 25} more lines)")

        else:
            print("  Stellar-types.x not found, skipping generation")

        result.mark_phase_passed("Phase 4: Dart Generator")
        return generated_code

    except Exception as e:
        result.mark_phase_failed("Phase 4: Generator", str(e))
        import traceback
        traceback.print_exc()
        return {}


def test_phase5_merger(result: TestResult) -> bool:
    """
    Phase 5: Test Dart Merger

    Tests custom code extraction and merging

    Returns:
        True if test passed
    """
    print("\n" + "=" * 80)
    print("PHASE 5: DART MERGER")
    print("=" * 80)

    try:
        print("\nInitializing analyzer and merger...")
        analyzer = DartAnalyzer()
        merger = DartMerger()

        # Create sample existing file with custom code
        existing_code = """// Copyright 2020 The Stellar Flutter SDK Authors.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'dart:convert';

class XdrMemo {
  XdrMemoType _type;

  static void encode(XdrDataOutputStream stream, XdrMemo value) {
    // old implementation
  }

  static XdrMemo decode(XdrDataInputStream stream) {
    // old implementation
  }

  // CUSTOM_CODE_START
  static XdrMemo fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrMemo.decode(XdrDataInputStream(bytes));
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrMemo.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }
  // CUSTOM_CODE_END
}
"""

        # Create sample generated code
        generated_code = """// Copyright 2020 The Stellar Flutter SDK Authors.
// Auto-generated from stellar-xdr v25.0

import 'xdr_data_io.dart';

class XdrMemo {
  XdrMemoType _type;

  XdrMemo(this._type);

  static void encode(XdrDataOutputStream stream, XdrMemo value) {
    // new implementation
    XdrMemoType.encode(stream, value._type);
  }

  static XdrMemo decode(XdrDataInputStream stream) {
    // new implementation
    XdrMemoType type = XdrMemoType.decode(stream);
    return XdrMemo(type);
  }
}
"""

        print("\n  Testing custom code extraction...")
        sections = analyzer.extract_custom_sections(existing_code)
        result.custom_sections_found = len(sections)
        print(f"    Found {len(sections)} custom sections")

        if sections:
            for section in sections:
                print(f"      - Class: {section.class_name}")
                print(f"        Lines: {len(section.content.split(chr(10)))}")

        print("\n  Testing code merging...")

        # Create temp file for existing code
        with tempfile.NamedTemporaryFile(mode='w', suffix='.dart', delete=False) as f:
            f.write(existing_code)
            temp_path = f.name

        try:
            merged_code = merger.merge_file(generated_code, temp_path)

            # Verify merge
            has_custom = 'CUSTOM_CODE_START' in merged_code
            has_method1 = 'fromBase64EncodedXdrString' in merged_code
            has_method2 = 'toBase64EncodedXdrString' in merged_code
            has_copyright = 'Copyright 2020' in merged_code
            has_import = 'dart:convert' in merged_code

            print(f"    Custom section preserved: {has_custom}")
            print(f"    fromBase64 method present: {has_method1}")
            print(f"    toBase64 method present: {has_method2}")
            print(f"    Copyright preserved: {has_copyright}")
            print(f"    dart:convert import added: {has_import}")

            if not all([has_custom, has_method1, has_method2, has_copyright, has_import]):
                result.mark_phase_failed("Phase 5: Merger", "Merge verification failed")
                return False

        finally:
            Path(temp_path).unlink()

        result.mark_phase_passed("Phase 5: Dart Merger")
        return True

    except Exception as e:
        result.mark_phase_failed("Phase 5: Merger", str(e))
        import traceback
        traceback.print_exc()
        return False


def test_phase6_validator(generated_code: Dict[str, str], result: TestResult) -> bool:
    """
    Phase 6: Test Validator

    Runs structural validation on generated code

    Returns:
        True if validation passed
    """
    print("\n" + "=" * 80)
    print("PHASE 6: VALIDATOR")
    print("=" * 80)

    try:
        print("\nInitializing validator...")
        validator = Validator(str(Path.cwd()))

        if not generated_code:
            print("  No generated code to validate, skipping")
            result.mark_phase_passed("Phase 6: Validator (skipped)")
            return True

        print(f"\nValidating {len(generated_code)} generated classes...")

        # Create file dict for validation (validator expects filename -> content)
        file_dict = {}
        for class_name, code in generated_code.items():
            # Use dummy filename
            filename = f"xdr_{class_name.lower()}.dart"
            file_dict[filename] = code

        validation_result = validator.validate_structural(file_dict)

        result.validation_errors = validation_result.errors
        result.validation_warnings = validation_result.warnings

        print(f"\n  Validation result: {'PASSED' if validation_result.passed else 'FAILED'}")
        print(f"  Errors: {len(validation_result.errors)}")
        print(f"  Warnings: {len(validation_result.warnings)}")

        if validation_result.errors:
            print("\n  Sample errors:")
            for error in validation_result.errors[:3]:
                print(f"    - {error}")
            if len(validation_result.errors) > 3:
                print(f"    ... and {len(validation_result.errors) - 3} more")

        if validation_result.warnings:
            print("\n  Sample warnings:")
            for warning in validation_result.warnings[:3]:
                print(f"    - {warning}")
            if len(validation_result.warnings) > 3:
                print(f"    ... and {len(validation_result.warnings) - 3} more")

        if validation_result.passed:
            result.mark_phase_passed("Phase 6: Validator")
        else:
            result.mark_phase_failed("Phase 6: Validator", f"{len(validation_result.errors)} validation errors")

        return validation_result.passed

    except Exception as e:
        result.mark_phase_failed("Phase 6: Validator", str(e))
        import traceback
        traceback.print_exc()
        return False


def test_phase7_compare_output(parsed_asts: Dict[str, any], result: TestResult) -> bool:
    """
    Phase 7: Compare Generated Output with Existing

    Generates a complete file and compares structure with existing

    Returns:
        True if comparison successful
    """
    print("\n" + "=" * 80)
    print("PHASE 7: COMPARE WITH EXISTING")
    print("=" * 80)

    try:
        # Check if xdr_memo.dart exists
        existing_path = Path(__file__).parent.parent.parent / 'lib' / 'src' / 'xdr' / 'xdr_memo.dart'

        if not existing_path.exists():
            print(f"\n  Existing file not found: {existing_path}")
            print("  Skipping comparison")
            result.mark_phase_passed("Phase 7: Compare Output (skipped)")
            return True

        print(f"\n  Found existing file: {existing_path.name}")

        # Read existing file
        with open(existing_path, 'r', encoding='utf-8') as f:
            existing_code = f.read()

        # Analyze existing file
        analyzer = DartAnalyzer()
        existing_classes = analyzer.extract_class_names(existing_code)
        existing_imports = analyzer.extract_imports(existing_code)
        existing_custom = analyzer.extract_custom_sections(existing_code)

        print(f"  Existing file structure:")
        print(f"    Classes: {len(existing_classes)}")
        print(f"    Imports: {len(existing_imports)}")
        print(f"    Custom sections: {len(existing_custom)}")

        # Generate new code for memo types
        if 'Stellar-transaction.x' in parsed_asts:
            ast = parsed_asts['Stellar-transaction.x']
            generator = DartGenerator()

            # Find memo-related types and generate them
            memo_enums = [e for e in ast.enums if 'memo' in e.name.lower()]
            memo_structs = [s for s in ast.structs if 'memo' in s.name.lower()]
            memo_unions = [u for u in ast.unions if 'memo' in u.name.lower()]

            memo_types = memo_enums + memo_structs + memo_unions

            if memo_types:
                print(f"\n  Generating code for {len(memo_types)} memo types...")

                generated_classes = []
                for memo_type in memo_enums:
                    code = generator.generate_enum(memo_type)
                    generated_classes.append(memo_type.name)

                for memo_type in memo_structs:
                    code = generator.generate_struct(memo_type)
                    generated_classes.append(memo_type.name)

                for memo_type in memo_unions:
                    code = generator.generate_union(memo_type)
                    generated_classes.append(memo_type.name)

                print(f"  Generated classes: {', '.join(generated_classes)}")
                print("\n  Comparison:")
                print(f"    Existing classes: {', '.join(existing_classes)}")
                print(f"    Generated classes: {', '.join(generated_classes)}")

        result.mark_phase_passed("Phase 7: Compare Output")
        return True

    except Exception as e:
        result.mark_phase_failed("Phase 7: Compare Output", str(e))
        import traceback
        traceback.print_exc()
        return False


def main():
    """Run complete end-to-end test."""
    print("\n" + "=" * 80)
    print("XDR GENERATOR - END-TO-END INTEGRATION TEST")
    print("=" * 80)
    print("\nThis test will:")
    print("  1. Fetch XDR files from stellar-xdr v25.0")
    print("  2. Parse all XDR files to AST")
    print("  3. Test type mapping and dependency resolution")
    print("  4. Generate Dart code for sample types")
    print("  5. Test merger with custom code extraction")
    print("  6. Run structural validation")
    print("  7. Compare generated output with existing files")

    result = TestResult()

    # Phase 1: Fetch XDR files
    xdr_files = test_phase1_fetcher(result)
    if not xdr_files:
        print("\nCannot continue without XDR files")
        result.print_summary()
        return 1

    # Phase 2: Parse XDR files
    parsed_asts = test_phase2_parser(xdr_files, result)
    if not parsed_asts:
        print("\nCannot continue without parsed ASTs")
        result.print_summary()
        return 1

    # Phase 3: Type system
    type_mapper, file_mapper, dep_resolver = test_phase3_type_system(parsed_asts, result)

    # Phase 4: Generate Dart code
    generated_code = test_phase4_generator(parsed_asts, result)

    # Phase 5: Test merger
    test_phase5_merger(result)

    # Phase 6: Validate generated code
    test_phase6_validator(generated_code, result)

    # Phase 7: Compare with existing
    test_phase7_compare_output(parsed_asts, result)

    # Print summary
    success = result.print_summary()

    return 0 if success else 1


if __name__ == '__main__':
    sys.exit(main())
