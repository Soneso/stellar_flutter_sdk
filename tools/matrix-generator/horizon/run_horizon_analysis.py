#!/usr/bin/env python3
"""
Horizon Compatibility Matrix Generator - Complete Automation Pipeline

This script automates the complete Horizon compatibility analysis workflow:
1. Fetches the latest Horizon release from GitHub
2. Downloads and parses the router.go source code
3. Analyzes the Flutter SDK implementation
4. Generates comparison reports and compatibility matrices
5. Outputs all results with detailed progress reporting

Author: Stellar Flutter SDK Team
License: Apache-2.0

Usage:
    # Run full automated analysis (default)
    python run_horizon_analysis.py

    # Use specific Horizon version
    python run_horizon_analysis.py --horizon-version v2.30.0

    # Use local router.go (for testing/development)
    python run_horizon_analysis.py --local /path/to/router.go

    # Verbose output
    python run_horizon_analysis.py --verbose
"""

import argparse
import sys
import traceback
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional

# Add parent dir to path for shared modules (common, github_fetcher, sdk_analyzer)
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    from common import ProgressTracker
    from github_fetcher import (
        get_latest_release,
        fetch_router_source,
        GitHubFetchError,
        ReleaseNotFoundError,
        SourceFileNotFoundError,
        is_authenticated
    )
    from horizon_parser import HorizonRouterParser
    from sdk_analyzer import FlutterSDKAnalyzer
    from generate_horizon_comparison import HorizonSDKComparator
except ImportError as e:
    print(f"ERROR: Failed to import required module: {e}")
    print("Please ensure all required modules are in the same directory.")
    sys.exit(1)


class HorizonAnalysisPipeline:
    """Main pipeline orchestrator for Horizon compatibility analysis"""

    def __init__(
        self,
        horizon_version: Optional[str] = None,
        local_router_path: Optional[str] = None,
        verbose: bool = False
    ):
        """
        Initialize the pipeline.

        Args:
            horizon_version: Specific Horizon version tag (e.g., 'v2.30.0'). None = latest
            local_router_path: Path to local router.go file. None = fetch from GitHub
            verbose: Enable verbose output
        """
        self.horizon_version = horizon_version
        self.local_router_path = local_router_path
        self.verbose = verbose
        self.progress = ProgressTracker(verbose=verbose)

        # Define paths
        self.project_root = Path(__file__).parent.parent.parent.parent
        self.data_dir = Path(__file__).parent.parent / "data" / "horizon"
        self.horizon_dir = self.project_root / "compatibility" / "horizon"

        # Ensure data directory exists
        self.data_dir.mkdir(parents=True, exist_ok=True)

        # Output file paths
        self.horizon_endpoints_file = self.data_dir / "horizon_endpoints.json"
        self.sdk_implementation_file = self.data_dir / "flutter_sdk_implementation.json"
        self.comparison_file = self.data_dir / "compatibility_comparison.json"
        self.statistics_file = self.data_dir / "coverage_stats.json"
        self.markdown_file = self.horizon_dir / "HORIZON_COMPATIBILITY_MATRIX.md"

        # Runtime data
        self.release_info: Optional[Dict[str, Any]] = None
        self.router_source: Optional[str] = None

    def run(self) -> int:
        """
        Execute the complete analysis pipeline.

        Returns:
            Exit code (0 = success, 1 = failure)
        """
        print("Horizon Compatibility Matrix Generator")
        print("=" * 60)

        try:
            # Step 1: Fetch Horizon release
            self.fetch_horizon_release()

            # Step 2: Parse Horizon endpoints
            self.parse_horizon_endpoints()

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

    def fetch_horizon_release(self) -> None:
        """Step 1: Fetch Horizon release information and source code"""
        self.progress.start_step("Fetching Horizon Release")

        if self.local_router_path:
            # Using local file
            local_path = Path(self.local_router_path)
            if not local_path.exists():
                raise FileNotFoundError(f"Local router.go not found: {local_path}")

            self.progress.log(f"Using local file: {local_path}", force=True)
            self.router_source = local_path.read_text(encoding='utf-8')

            # Create minimal release info for local mode
            self.release_info = {
                'version': 'local',
                'published_at': datetime.now().strftime('%Y-%m-%d'),
                'html_url': str(local_path),
                'source': 'local'
            }

            self.progress.finish_step(f"Loaded {len(self.router_source)} bytes from local file")

        else:
            # Fetch from GitHub
            try:
                # Show authentication status
                if is_authenticated():
                    self.progress.log("GitHub: Authenticated (5,000 req/hour)", force=True)
                else:
                    self.progress.log("GitHub: Unauthenticated (60 req/hour)", force=True)
                    self.progress.log("  Tip: Set GITHUB_TOKEN for higher limits", force=True)

                if self.horizon_version:
                    # Use specific version
                    self.progress.log(f"Fetching Horizon version: {self.horizon_version}", force=True)
                    self.router_source = fetch_router_source(self.horizon_version)
                    self.release_info = {
                        'version': self.horizon_version,
                        'published_at': 'unknown',
                        'html_url': f'https://github.com/stellar/stellar-horizon/releases/tag/{self.horizon_version}',
                        'source': 'GitHub'
                    }
                else:
                    # Fetch latest release
                    self.progress.log("Fetching latest Horizon release...", force=True)
                    release = get_latest_release()
                    self.router_source = fetch_router_source(release.version)
                    self.release_info = {
                        'version': release.version,
                        'published_at': release.published_at.strftime('%Y-%m-%d'),
                        'html_url': release.html_url,
                        'source': 'GitHub'
                    }

                self.progress.log(f"Version: {self.release_info['version']}", force=True)
                self.progress.log(f"Published: {self.release_info['published_at']}", force=True)
                self.progress.log(f"Source: {self.release_info['html_url']}", force=True)
                self.progress.finish_step(f"Downloaded {len(self.router_source)} bytes")

            except (ReleaseNotFoundError, SourceFileNotFoundError, GitHubFetchError) as e:
                raise RuntimeError(f"Failed to fetch Horizon release: {e}") from e

    def parse_horizon_endpoints(self) -> None:
        """Step 2: Parse Horizon router.go and extract endpoints"""
        self.progress.start_step("Parsing Horizon Endpoints")

        if not self.router_source:
            raise RuntimeError("No router source available. Step 1 must complete first.")

        # Prepare version info for parser
        version_info = {
            'horizon_version': self.release_info['version'],
            'published_at': self.release_info['published_at'],
            'release_url': self.release_info['html_url']
        }

        # Parse router source
        parser = HorizonRouterParser(version_info=version_info)
        parser.parse_from_content(self.router_source)

        # Save results
        parser.save_json(str(self.horizon_endpoints_file))

        endpoints_count = len(parser.endpoints)
        categories_count = len(parser.categories)
        self.progress.finish_step(
            f"Found {endpoints_count} endpoints in {categories_count} categories"
        )

    def analyze_flutter_sdk(self) -> None:
        """Step 3: Analyze Flutter SDK implementation"""
        self.progress.start_step("Analyzing Flutter SDK")

        # Analyze SDK
        analyzer = FlutterSDKAnalyzer(str(self.project_root))
        analyzer.analyze()

        # Save results
        analyzer.save_json(str(self.sdk_implementation_file))

        from common import get_sdk_version
        sdk_version = get_sdk_version()
        builders_count = len(analyzer.builders)
        exposed_count = len(analyzer.exposed_builders)

        self.progress.finish_step(
            f"Found {builders_count} request builders ({exposed_count} exposed), SDK v{sdk_version}"
        )

    def generate_comparison_reports(self) -> None:
        """Step 4: Generate compatibility comparison reports"""
        self.progress.start_step("Generating Compatibility Reports")

        # Create comparator
        comparator = HorizonSDKComparator(
            str(self.horizon_endpoints_file),
            str(self.sdk_implementation_file)
        )

        # Load data
        comparator.load_data()

        # Compare endpoints
        comparator.compare_endpoints()

        # Generate all reports
        self.progress.log("Generating comparison JSON...", force=False)
        comparator.generate_comparison_report(str(self.comparison_file))

        self.progress.log("Generating statistics JSON...", force=False)
        comparator.generate_statistics_report(str(self.statistics_file))

        self.progress.log("Generating markdown matrix...", force=False)
        comparator.generate_markdown_report(str(self.markdown_file))

        # Calculate summary stats
        stats = comparator.calculate_statistics()
        overall = stats['overall']

        self.progress.finish_step(
            f"Coverage: {overall['coverage_percentage']}% "
            f"({overall['fully_supported']}/{overall['total_endpoints']} endpoints)"
        )

    def collect_statistics(self) -> Dict[str, Any]:
        """Collect final statistics for summary"""
        import json

        # Load statistics file
        with open(self.statistics_file, 'r', encoding='utf-8') as f:
            stats = json.load(f)

        # Collect file paths relative to project root
        generated_files = [
            str(self.horizon_endpoints_file.relative_to(self.project_root)),
            str(self.sdk_implementation_file.relative_to(self.project_root)),
            str(self.comparison_file.relative_to(self.project_root)),
            str(self.statistics_file.relative_to(self.project_root)),
            str(self.markdown_file.relative_to(self.project_root))
        ]

        return {
            'horizon_version': self.release_info['version'],
            'sdk_version': stats['sdk_version'],
            'coverage_percentage': stats['overall']['coverage_percentage'],
            'fully_supported': stats['overall']['fully_supported'],
            'total_endpoints': stats['overall']['total_endpoints'],
            'generated_files': generated_files
        }


def main() -> int:
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Automated Horizon API compatibility analysis pipeline",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run full automated analysis (fetch latest Horizon release)
  %(prog)s

  # Use specific Horizon version
  %(prog)s --horizon-version v2.30.0

  # Use local router.go file (for testing/development)
  %(prog)s --local /path/to/router.go

  # Enable verbose output
  %(prog)s --verbose

  # Combine options
  %(prog)s --horizon-version v2.29.0 --verbose
        """
    )

    parser.add_argument(
        '--horizon-version',
        type=str,
        metavar='VERSION',
        help='Specific Horizon version tag (e.g., v2.30.0). Default: latest release'
    )

    parser.add_argument(
        '--local',
        type=str,
        metavar='PATH',
        help='Path to local router.go file (skips GitHub fetch)'
    )

    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Enable verbose output with detailed progress'
    )

    args = parser.parse_args()

    # Create and run pipeline
    pipeline = HorizonAnalysisPipeline(
        horizon_version=args.horizon_version,
        local_router_path=args.local,
        verbose=args.verbose
    )

    return pipeline.run()


if __name__ == '__main__':
    sys.exit(main())
