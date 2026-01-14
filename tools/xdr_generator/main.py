"""
XDR Code Generator CLI

Command-line interface for generating Dart XDR files from Stellar XDR definitions.

Usage:
    # Generate from latest release
    python -m tools.xdr_generator

    # Generate from specific version
    python -m tools.xdr_generator --version v22.0

    # List available versions
    python -m tools.xdr_generator --list-versions

    # Show what types would be generated (not yet implemented)
    python -m tools.xdr_generator --list-types

    # Verbose output
    python -m tools.xdr_generator --verbose
"""

import argparse
import sys
from pathlib import Path
from typing import Optional

from . import __version__
from .error_handler import GeneratorErrorHandler
from .xdr_fetcher import (
    get_available_versions,
    get_latest_version,
    fetch_xdr_files,
    ReleaseNotFoundError,
    XdrFileNotFoundError,
    GitHubFetchError,
    is_authenticated,
)
from .xdr_lexer import XdrLexer
from .xdr_parser import XdrParser
from .type_mapping import TypeMapper
from .file_mapping import FileMapper
from .dart_generator import DartGenerator
from .dart_merger import DartMerger
from .validator import Validator


def setup_argument_parser() -> argparse.ArgumentParser:
    """
    Create and configure argument parser.

    Returns:
        Configured ArgumentParser instance
    """
    parser = argparse.ArgumentParser(
        prog='xdr_generator',
        description='Generate Dart XDR files from Stellar XDR definitions',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate from latest release
  python -m tools.xdr_generator

  # Generate from specific version
  python -m tools.xdr_generator --version v22.0

  # List available XDR versions
  python -m tools.xdr_generator --list-versions

  # Show types that would be generated
  python -m tools.xdr_generator --list-types

Authentication:
  Set GITHUB_TOKEN environment variable to avoid API rate limits:
  export GITHUB_TOKEN=your_token

  Or configure gh CLI (token auto-detected):
  gh auth login
        """
    )

    parser.add_argument(
        '--version', '-v',
        metavar='VERSION',
        default='latest',
        help='XDR release version to generate from (default: latest)'
    )

    parser.add_argument(
        '--output', '-o',
        metavar='DIR',
        default='lib/src/xdr/',
        help='Output directory for generated files (default: lib/src/xdr/)'
    )

    parser.add_argument(
        '--list-versions',
        action='store_true',
        help='List all available XDR release versions and exit'
    )

    parser.add_argument(
        '--list-types',
        action='store_true',
        help='List types that would be generated and exit (not yet implemented)'
    )

    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Enable verbose output'
    )

    parser.add_argument(
        '--skip-tests',
        action='store_true',
        help='Skip test suite validation (faster, but less thorough)'
    )

    parser.add_argument(
        '--skip-validation',
        action='store_true',
        help='Skip all validation (not recommended)'
    )

    parser.add_argument(
        '--show-version',
        action='version',
        version=f'xdr_generator {__version__}'
    )

    return parser


def list_versions(verbose: bool = False) -> int:
    """
    List all available XDR release versions.

    Args:
        verbose: Enable verbose output

    Returns:
        Exit code (0 for success, 1 for error)
    """
    try:
        # Show authentication status
        if verbose:
            if is_authenticated():
                print("Authentication: Enabled (5,000 requests/hour)")
            else:
                print("Authentication: Not configured (60 requests/hour)")
                print("  Tip: Set GITHUB_TOKEN env var to avoid rate limits")
            print()

        print("Fetching available XDR versions...")
        versions = get_available_versions()

        print(f"\nFound {len(versions)} stellar-xdr releases:\n")

        # Print versions in a nicely formatted table
        print(f"{'Version':<15} {'Published':<12} {'URL'}")
        print("-" * 70)

        for version in versions:
            published = version.published_at.strftime('%Y-%m-%d')
            url = version.html_url
            print(f"{version.version:<15} {published:<12} {url}")

        print("\nUse --version/-v to specify a version for generation.")
        print("Example: python -m tools.xdr_generator --version v22.0")

        return 0

    except ReleaseNotFoundError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    except GitHubFetchError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"UNEXPECTED ERROR: {e}", file=sys.stderr)
        if verbose:
            import traceback
            traceback.print_exc()
        return 1


def list_types(version: str, verbose: bool = False) -> int:
    """
    List types that would be generated for a specific version.

    Args:
        version: XDR version to list types for
        verbose: Enable verbose output

    Returns:
        Exit code (0 for success, 1 for error)
    """
    try:
        # Show authentication status
        if verbose:
            if is_authenticated():
                print("Authentication: Enabled (5,000 requests/hour)")
            else:
                print("Authentication: Not configured (60 requests/hour)")
            print()

        # Resolve version
        if version.lower() == 'latest':
            if verbose:
                print("Fetching latest XDR version...")
            latest = get_latest_version()
            version = latest.version

        print(f"Listing types for stellar-xdr {version}...")

        # Fetch XDR files
        xdr_files, _ = fetch_xdr_files(version)

        # Parse and collect all types
        type_mapper = TypeMapper()
        all_types = {'enums': [], 'structs': [], 'unions': [], 'typedefs': []}

        for filename, content in sorted(xdr_files.items()):
            lexer = XdrLexer(content, filename)
            tokens = lexer.tokenize()
            parser = XdrParser(tokens, filename)
            ast = parser.parse()

            for enum in ast.enums:
                dart_name = type_mapper.get_dart_class_name(enum.name)
                all_types['enums'].append((enum.name, dart_name))

            for struct in ast.structs:
                dart_name = type_mapper.get_dart_class_name(struct.name)
                all_types['structs'].append((struct.name, dart_name))

            for union in ast.unions:
                dart_name = type_mapper.get_dart_class_name(union.name)
                all_types['unions'].append((union.name, dart_name))

            for typedef in ast.typedefs:
                dart_name = type_mapper.get_dart_class_name(typedef.name)
                all_types['typedefs'].append((typedef.name, dart_name))

        # Print summary
        total = sum(len(v) for v in all_types.values())
        print(f"\nFound {total} types:\n")

        print(f"Enums ({len(all_types['enums'])}):")
        for xdr_name, dart_name in sorted(all_types['enums']):
            if verbose:
                print(f"  {xdr_name:40} -> {dart_name}")
            else:
                print(f"  {dart_name}")

        print(f"\nStructs ({len(all_types['structs'])}):")
        for xdr_name, dart_name in sorted(all_types['structs']):
            if verbose:
                print(f"  {xdr_name:40} -> {dart_name}")
            else:
                print(f"  {dart_name}")

        print(f"\nUnions ({len(all_types['unions'])}):")
        for xdr_name, dart_name in sorted(all_types['unions']):
            if verbose:
                print(f"  {xdr_name:40} -> {dart_name}")
            else:
                print(f"  {dart_name}")

        if verbose:
            print(f"\nTypedefs ({len(all_types['typedefs'])}):")
            for xdr_name, dart_name in sorted(all_types['typedefs']):
                print(f"  {xdr_name:40} -> {dart_name}")

        return 0

    except ReleaseNotFoundError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    except GitHubFetchError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"UNEXPECTED ERROR: {e}", file=sys.stderr)
        if verbose:
            import traceback
            traceback.print_exc()
        return 1


def generate_xdr(
    version: str,
    output_dir: str,
    skip_tests: bool = False,
    skip_validation: bool = False,
    verbose: bool = False
) -> int:
    """
    Generate Dart XDR files from Stellar XDR definitions.

    Args:
        version: XDR version to generate from
        output_dir: Output directory for generated files
        skip_tests: Skip test suite validation
        skip_validation: Skip all validation
        verbose: Enable verbose output

    Returns:
        Exit code (0 for success, 1 for error)
    """
    try:
        # Show authentication status
        if verbose:
            if is_authenticated():
                print("Authentication: Enabled (5,000 requests/hour)")
            else:
                print("Authentication: Not configured (60 requests/hour)")
                print("  Tip: Set GITHUB_TOKEN env var to avoid rate limits")
            print()

        # Resolve version
        if version.lower() == 'latest':
            if verbose:
                print("Fetching latest XDR version...")
            latest = get_latest_version()
            version = latest.version
            print(f"Using latest version: {version}")
        else:
            print(f"Using specified version: {version}")

        # Step 1: Fetch XDR files
        if verbose:
            print(f"\nStep 1: Fetching XDR files for {version}...")

        xdr_files, failed_files = fetch_xdr_files(version)

        print(f"Fetched {len(xdr_files)} XDR files:")
        for filename in sorted(xdr_files.keys()):
            if verbose:
                lines = xdr_files[filename].count('\n') + 1
                print(f"  {filename}: {len(xdr_files[filename])} bytes, {lines} lines")
            else:
                print(f"  {filename}")

        if failed_files:
            print(f"\nWarning: {len(failed_files)} files failed to fetch:")
            for filename in failed_files:
                print(f"  {filename}")

        # Step 2: Parse XDR files to AST
        if verbose:
            print(f"\nStep 2: Parsing XDR files...")

        parsed_asts = {}
        total_types = {'constants': 0, 'typedefs': 0, 'enums': 0, 'structs': 0, 'unions': 0}

        for filename, content in sorted(xdr_files.items()):
            lexer = XdrLexer(content, filename)
            tokens = lexer.tokenize()
            parser = XdrParser(tokens, filename)
            ast = parser.parse()
            parsed_asts[filename] = ast

            counts = ast.count_definitions()
            total_types['constants'] += counts[0]
            total_types['typedefs'] += counts[1]
            total_types['enums'] += counts[2]
            total_types['structs'] += counts[3]
            total_types['unions'] += counts[4]

            if verbose:
                print(f"  {filename}: {sum(counts)} types")

        print(f"Parsed {sum(total_types.values())} total types")
        if verbose:
            print(f"  Constants: {total_types['constants']}, Typedefs: {total_types['typedefs']}, "
                  f"Enums: {total_types['enums']}, Structs: {total_types['structs']}, Unions: {total_types['unions']}")

        # Step 3: Initialize type system components
        if verbose:
            print(f"\nStep 3: Initializing type system...")

        type_mapper = TypeMapper()
        file_mapper = FileMapper(output_dir if Path(output_dir).exists() else None)
        generator = DartGenerator(type_mapper, file_mapper)

        # Step 4: Group types by target Dart file
        if verbose:
            print(f"\nStep 4: Grouping types by output file...")

        # Collect all definitions from all XDR files
        all_enums = []
        all_structs = []
        all_unions = []
        all_typedefs = []

        for ast in parsed_asts.values():
            all_enums.extend(ast.enums)
            all_structs.extend(ast.structs)
            all_unions.extend(ast.unions)
            all_typedefs.extend(ast.typedefs)

        # Group by target file based on existing mapping or infer from name
        file_to_definitions = {}

        for enum in all_enums:
            dart_name = type_mapper.get_dart_class_name(enum.name)
            target_file = file_mapper.get_target_file(dart_name) or file_mapper.infer_file_for_type(dart_name)
            file_to_definitions.setdefault(target_file, []).append(('enum', enum))

        for struct in all_structs:
            dart_name = type_mapper.get_dart_class_name(struct.name)
            target_file = file_mapper.get_target_file(dart_name) or file_mapper.infer_file_for_type(dart_name)
            file_to_definitions.setdefault(target_file, []).append(('struct', struct))

        for union in all_unions:
            dart_name = type_mapper.get_dart_class_name(union.name)
            target_file = file_mapper.get_target_file(dart_name) or file_mapper.infer_file_for_type(dart_name)
            file_to_definitions.setdefault(target_file, []).append(('union', union))

        print(f"Types grouped into {len(file_to_definitions)} files")

        # Step 5: Generate Dart code for each file
        if verbose:
            print(f"\nStep 5: Generating Dart code...")

        generated_files = {}

        for target_file, definitions in sorted(file_to_definitions.items()):
            if not target_file:
                target_file = 'xdr_other.dart'

            # Generate header
            lines = []
            lines.append(generator.generate_file_header(version))

            # Add standard imports
            lines.append("import 'dart:typed_data';")
            lines.append("import 'xdr_data_io.dart';")
            lines.append('')

            # Generate each type
            for def_type, definition in definitions:
                if def_type == 'enum':
                    lines.append(generator.generate_enum(definition))
                elif def_type == 'struct':
                    lines.append(generator.generate_struct(definition))
                elif def_type == 'union':
                    lines.append(generator.generate_union(definition))
                lines.append('')

            generated_files[target_file] = '\n'.join(lines)

            if verbose:
                print(f"  {target_file}: {len(definitions)} types")

        print(f"Generated {len(generated_files)} Dart files")

        # Step 6: Merge with existing custom code
        # Always look in the standard lib/src/xdr/ directory for existing custom code
        sdk_xdr_dir = Path.cwd() / 'lib' / 'src' / 'xdr'
        if verbose:
            print(f"\nStep 6: Merging with existing custom code from {sdk_xdr_dir}...")

        merger = DartMerger()
        merged_files = {}

        for filename, content in generated_files.items():
            existing_path = sdk_xdr_dir / filename
            if existing_path.exists():
                try:
                    merged = merger.merge_file(content, str(existing_path))
                    merged_files[filename] = merged
                    if merger._last_missing_classes:
                        print(f"  {filename}: merged (missing classes: {', '.join(merger._last_missing_classes)})")
                    elif verbose:
                        print(f"  {filename}: merged with existing")
                except Exception as e:
                    print(f"  Warning: Could not merge {filename}: {e}")
                    merged_files[filename] = content
            else:
                merged_files[filename] = content
                if verbose:
                    print(f"  {filename}: new file")

        # Step 7: Validate output (optional)
        if not skip_validation:
            if verbose:
                print(f"\nStep 7: Validating output...")

            validator = Validator(str(Path.cwd()))
            result = validator.validate_structural(merged_files)

            print(f"Validation: {'PASSED' if result.passed else 'FAILED'}")
            if result.errors:
                print(f"  Errors: {len(result.errors)}")
                for error in result.errors[:5]:
                    print(f"    - {error}")
                if len(result.errors) > 5:
                    print(f"    ... and {len(result.errors) - 5} more")

            if result.warnings:
                print(f"  Warnings: {len(result.warnings)}")

            if not result.passed:
                print("\nValidation failed. Files not written.", file=sys.stderr)
                return 1
        else:
            if verbose:
                print(f"\nStep 7: Skipping validation...")

        # Step 8: Write output files
        if verbose:
            print(f"\nStep 8: Writing output files to {output_dir}...")

        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        for filename, content in merged_files.items():
            filepath = output_path / filename
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            if verbose:
                print(f"  Wrote {filename}")

        print(f"\nGeneration complete! {len(merged_files)} files written to {output_dir}")
        return 0

    except ReleaseNotFoundError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    except XdrFileNotFoundError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    except GitHubFetchError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"UNEXPECTED ERROR: {e}", file=sys.stderr)
        if verbose:
            import traceback
            traceback.print_exc()
        return 1


def main(argv: Optional[list] = None) -> int:
    """
    Main entry point for XDR generator CLI.

    Args:
        argv: Command-line arguments (defaults to sys.argv)

    Returns:
        Exit code (0 for success, 1 for error)
    """
    parser = setup_argument_parser()
    args = parser.parse_args(argv)

    # Handle commands
    if args.list_versions:
        return list_versions(verbose=args.verbose)

    if args.list_types:
        return list_types(version=args.version, verbose=args.verbose)

    # Default: generate XDR code
    return generate_xdr(
        version=args.version,
        output_dir=args.output,
        skip_tests=args.skip_tests,
        skip_validation=args.skip_validation,
        verbose=args.verbose
    )


if __name__ == '__main__':
    sys.exit(main())
