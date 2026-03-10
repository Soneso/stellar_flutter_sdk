#!/usr/bin/env python3
"""
Soroban RPC Compatibility Matrix Generator - Complete Automation Pipeline

This script automates the complete Soroban RPC compatibility analysis workflow:
1. Fetches the latest RPC release from GitHub
2. Downloads and parses the jsonrpc.go source code
3. Analyzes the Flutter SDK Soroban implementation
4. Generates comparison reports and compatibility matrices
5. Outputs all results with detailed progress reporting

Author: Stellar Flutter SDK Team
License: Apache-2.0

Usage:
    # Run full automated analysis (default)
    python run_rpc_analysis.py

    # Use specific RPC version
    python run_rpc_analysis.py --rpc-version v22.0.0

    # Use local jsonrpc.go (for testing/development)
    python run_rpc_analysis.py --local /path/to/jsonrpc.go

    # Verbose output
    python run_rpc_analysis.py --verbose
"""

import argparse
import json
import sys
import traceback
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional

# Add parent dir to path for shared modules (common, github_fetcher)
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    from common import ProgressTracker
    from github_fetcher import (
        get_latest_rpc_release,
        fetch_rpc_jsonrpc_source,
        fetch_all_rpc_response_files,
        GitHubFetchError,
        ReleaseNotFoundError,
        SourceFileNotFoundError,
        is_authenticated
    )
    from rpc_parser import RPCMethodParser
    from generate_rpc_comparison import (
        SorobanSDKAnalyzer,
        RPCComparisonAnalyzer
    )
except ImportError as e:
    print(f"ERROR: Failed to import required module: {e}")
    print("Please ensure all required modules are in the same directory.")
    sys.exit(1)


class RPCAnalysisPipeline:
    """Main pipeline orchestrator for RPC compatibility analysis"""

    def __init__(
        self,
        rpc_version: Optional[str] = None,
        local_jsonrpc_path: Optional[str] = None,
        verbose: bool = False
    ):
        """
        Initialize the pipeline.

        Args:
            rpc_version: Specific RPC version tag (e.g., 'v22.0.0'). None = latest
            local_jsonrpc_path: Path to local jsonrpc.go file. None = fetch from GitHub
            verbose: Enable verbose output
        """
        self.rpc_version = rpc_version
        self.local_jsonrpc_path = local_jsonrpc_path
        self.verbose = verbose
        self.progress = ProgressTracker(verbose=verbose)

        # Define paths
        self.project_root = Path(__file__).parent.parent.parent.parent
        self.data_dir = Path(__file__).parent.parent / "data" / "rpc"
        self.rpc_dir = self.project_root / "compatibility" / "rpc"

        # Ensure data directory exists
        self.data_dir.mkdir(parents=True, exist_ok=True)

        # Output file paths
        self.rpc_methods_file = self.data_dir / "rpc_methods.json"
        self.sdk_implementation_file = self.data_dir / "flutter_soroban_implementation.json"
        self.comparison_file = self.data_dir / "rpc_comparison.json"
        self.statistics_file = self.data_dir / "rpc_coverage_stats.json"
        self.markdown_file = self.rpc_dir / "RPC_COMPATIBILITY_MATRIX.md"

        # Runtime data
        self.release_info: Optional[Dict[str, Any]] = None
        self.jsonrpc_source: Optional[str] = None

    def run(self) -> int:
        """
        Execute the complete analysis pipeline.

        Returns:
            Exit code (0 = success, 1 = failure)
        """
        print("Soroban RPC Compatibility Matrix Generator")
        print("=" * 60)

        try:
            # Step 1: Fetch RPC release
            self.fetch_rpc_release()

            # Step 2: Parse RPC methods
            self.parse_rpc_methods()

            # Step 3: Analyze Flutter SDK
            self.analyze_flutter_sdk()

            # Step 4: Generate comparison reports
            self.generate_comparison_reports()

            # Print summary
            stats = self.collect_statistics()
            self.progress.print_summary(stats)

            return 0

        except Exception as e:
            print()
            print("=" * 60)
            print(f"ERROR: {str(e)}")
            print("=" * 60)
            if self.verbose:
                traceback.print_exc()
            return 1

    def fetch_rpc_release(self) -> None:
        """Step 1: Fetch RPC release information and source code"""
        self.progress.start_step("Fetching RPC Release")

        if self.local_jsonrpc_path:
            # Using local file
            local_path = Path(self.local_jsonrpc_path)
            if not local_path.exists():
                raise FileNotFoundError(f"Local jsonrpc.go not found: {local_path}")

            self.progress.log(f"Using local file: {local_path}", force=True)
            self.jsonrpc_source = local_path.read_text(encoding='utf-8')

            # Create minimal release info for local mode
            self.release_info = {
                'version': 'local',
                'published_at': datetime.now().strftime('%Y-%m-%d'),
                'html_url': str(local_path),
                'source': 'local'
            }

            self.progress.finish_step(f"Loaded {len(self.jsonrpc_source)} bytes from local file")

        else:
            # Fetch from GitHub
            try:
                # Show authentication status
                if is_authenticated():
                    self.progress.log("GitHub: Authenticated (5,000 req/hour)", force=True)
                else:
                    self.progress.log("GitHub: Unauthenticated (60 req/hour)", force=True)
                    self.progress.log("  Tip: Set GITHUB_TOKEN for higher limits", force=True)

                if self.rpc_version:
                    # Use specific version
                    self.progress.log(f"Fetching RPC version: {self.rpc_version}", force=True)
                    self.jsonrpc_source = fetch_rpc_jsonrpc_source(self.rpc_version)
                    self.release_info = {
                        'version': self.rpc_version,
                        'published_at': 'unknown',
                        'html_url': f'https://github.com/stellar/stellar-rpc/releases/tag/{self.rpc_version}',
                        'source': 'GitHub'
                    }
                else:
                    # Fetch latest release
                    self.progress.log("Fetching latest RPC release...", force=True)
                    release = get_latest_rpc_release()
                    self.jsonrpc_source = fetch_rpc_jsonrpc_source(release.version)
                    self.release_info = {
                        'version': release.version,
                        'published_at': release.published_at.strftime('%Y-%m-%d'),
                        'html_url': release.html_url,
                        'source': 'GitHub'
                    }

                self.progress.log(f"Version: {self.release_info['version']}", force=True)
                self.progress.log(f"Published: {self.release_info['published_at']}", force=True)
                self.progress.log(f"Source: {self.release_info['html_url']}", force=True)
                self.progress.finish_step(f"Downloaded {len(self.jsonrpc_source)} bytes")

            except (ReleaseNotFoundError, SourceFileNotFoundError, GitHubFetchError) as e:
                raise RuntimeError(f"Failed to fetch RPC release: {e}") from e

    def parse_rpc_methods(self) -> None:
        """Step 2: Parse jsonrpc.go and extract RPC methods"""
        self.progress.start_step("Parsing RPC Methods")

        if not self.jsonrpc_source:
            raise RuntimeError("No jsonrpc source available. Step 1 must complete first.")

        # Prepare version info for parser
        version_info = {
            'version': self.release_info['version'],
            'release_date': self.release_info['published_at'],
            'release_url': self.release_info['html_url']
        }

        # Parse jsonrpc source
        parser = RPCMethodParser(version_info=version_info)
        parser.parse(self.jsonrpc_source)

        methods_count = parser.get_method_count()
        self.progress.log(f"Found {methods_count} RPC methods", force=True)

        # Fetch and parse response struct files (if not local mode)
        if self.release_info['source'] != 'local':
            self.progress.log("Fetching response struct definitions...", force=True)
            try:
                method_names = parser.get_method_names()
                response_files = fetch_all_rpc_response_files(
                    self.release_info['version'],
                    method_names
                )

                self.progress.log(f"Found {len(response_files)} response struct files", force=True)

                # Parse response fields for each method
                for method_name, response_content in response_files.items():
                    parser.add_response_fields_to_method(method_name, response_content)

            except GitHubFetchError as e:
                self.progress.log(f"Warning: Could not fetch response files: {e}", force=True)
                self.progress.log("Continuing without response field analysis", force=True)

        # Save results
        parser.save_json(str(self.rpc_methods_file))

        self.progress.finish_step(f"Parsed {methods_count} methods with response fields")

    def analyze_flutter_sdk(self) -> None:
        """Step 3: Analyze Flutter SDK Soroban implementation"""
        self.progress.start_step("Analyzing Flutter SDK")

        # Locate soroban_server.dart
        soroban_server_path = self.project_root / "lib" / "src" / "soroban" / "soroban_server.dart"

        if not soroban_server_path.exists():
            raise FileNotFoundError(f"Soroban server file not found: {soroban_server_path}")

        # Analyze SDK
        analyzer = SorobanSDKAnalyzer(str(soroban_server_path))
        flutter_data = analyzer.analyze()

        # Save results
        with open(self.sdk_implementation_file, 'w', encoding='utf-8') as f:
            json.dump(flutter_data, f, indent=2, ensure_ascii=False)

        methods_count = flutter_data['metadata']['total_methods']
        self.progress.finish_step(f"Found {methods_count} Soroban methods in soroban_server.dart")

    def generate_comparison_reports(self) -> None:
        """Step 4: Generate compatibility comparison reports"""
        self.progress.start_step("Generating Compatibility Reports")

        # Load RPC methods data
        with open(self.rpc_methods_file, 'r', encoding='utf-8') as f:
            rpc_data = json.load(f)

        # Load Flutter implementation data
        with open(self.sdk_implementation_file, 'r', encoding='utf-8') as f:
            flutter_data = json.load(f)

        # Create analyzer
        analyzer = RPCComparisonAnalyzer(rpc_data, flutter_data)

        # Perform analysis
        analyzer.analyze()

        # Generate all reports
        self.progress.log("Generating comparison JSON...", force=False)
        comparison_data = analyzer.generate_comparison_data()
        with open(self.comparison_file, 'w', encoding='utf-8') as f:
            json.dump(comparison_data, f, indent=2, ensure_ascii=False)

        self.progress.log("Generating statistics JSON...", force=False)
        coverage_stats = analyzer.generate_coverage_stats()
        with open(self.statistics_file, 'w', encoding='utf-8') as f:
            json.dump(coverage_stats, f, indent=2, ensure_ascii=False)

        self.progress.log("Generating markdown matrix...", force=False)
        analyzer.generate_markdown_report(str(self.markdown_file))

        # Calculate summary stats
        overall = coverage_stats['overall']

        self.progress.finish_step(
            f"Coverage: {overall['coverage_percentage']}% "
            f"({overall['fully_supported']}/{overall['total_methods']} methods)"
        )

    def collect_statistics(self) -> Dict[str, Any]:
        """Collect final statistics for summary"""
        # Load statistics file
        with open(self.statistics_file, 'r', encoding='utf-8') as f:
            stats = json.load(f)

        # Collect file paths relative to project root
        generated_files = [
            str(self.rpc_methods_file.relative_to(self.project_root)),
            str(self.sdk_implementation_file.relative_to(self.project_root)),
            str(self.comparison_file.relative_to(self.project_root)),
            str(self.statistics_file.relative_to(self.project_root)),
            str(self.markdown_file.relative_to(self.project_root))
        ]

        # Get SDK version from comparison data (it's embedded in the analyzer)
        with open(self.comparison_file, 'r', encoding='utf-8') as f:
            comparison_data = json.load(f)

        return {
            'rpc_version': self.release_info['version'],
            'sdk_version': comparison_data['metadata']['sdk_version'],
            'coverage_percentage': stats['overall']['coverage_percentage'],
            'fully_supported': stats['overall']['fully_supported'],
            'total_methods': stats['overall']['total_methods'],
            'generated_files': generated_files
        }


def main() -> int:
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Automated Soroban RPC compatibility analysis pipeline",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run full automated analysis (fetch latest RPC release)
  %(prog)s

  # Use specific RPC version
  %(prog)s --rpc-version v22.0.0

  # Use local jsonrpc.go file (for testing/development)
  %(prog)s --local /path/to/jsonrpc.go

  # Enable verbose output
  %(prog)s --verbose

  # Combine options
  %(prog)s --rpc-version v21.5.0 --verbose
        """
    )

    parser.add_argument(
        '--rpc-version',
        type=str,
        metavar='VERSION',
        help='Specific RPC version tag (e.g., v22.0.0). Default: latest release'
    )

    parser.add_argument(
        '--local',
        type=str,
        metavar='PATH',
        help='Path to local jsonrpc.go file (skips GitHub fetch)'
    )

    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Enable verbose output with detailed progress'
    )

    args = parser.parse_args()

    # Create and run pipeline
    pipeline = RPCAnalysisPipeline(
        rpc_version=args.rpc_version,
        local_jsonrpc_path=args.local,
        verbose=args.verbose
    )

    return pipeline.run()


if __name__ == '__main__':
    sys.exit(main())
