#!/usr/bin/env python3
"""
Compatibility Analysis Orchestrator

Runs all compatibility analysis scripts in sequence with colored terminal output
and comprehensive error handling.

Author: Stellar Flutter SDK Team
License: Apache-2.0
"""

import sys
import subprocess
from pathlib import Path
from typing import List, Tuple
from datetime import datetime

from common import Colors, SDK_ROOT


class AnalysisOrchestrator:
    """Orchestrates the execution of all analysis scripts"""

    def __init__(self):
        """Initialize orchestrator"""
        self.tools_dir = Path(__file__).parent
        self.base_dir = self.tools_dir.parent.parent  # Go up two levels to SDK root
        self.scripts: List[Tuple[str, str, str]] = [
            ("horizon/run_horizon_analysis.py", "Generating Horizon compatibility report", "horizon"),
            ("rpc/run_rpc_analysis.py", "Generating RPC compatibility report", "rpc"),
            ("sep/sep_parser.py 0001", "Parsing SEP-01 (stellar.toml) specification", "sep"),
            ("sep/sep_analyzer.py 0001", "Analyzing SEP-01 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0001", "Generating SEP-01 compatibility report", "sep"),
            ("sep/sep_parser.py 0002", "Parsing SEP-02 (Federation) specification", "sep"),
            ("sep/sep_analyzer.py 0002", "Analyzing SEP-02 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0002", "Generating SEP-02 compatibility report", "sep"),
            ("sep/sep_parser.py 0005", "Parsing SEP-05 (Key Derivation) specification", "sep"),
            ("sep/sep_analyzer.py 0005", "Analyzing SEP-05 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0005", "Generating SEP-05 compatibility report", "sep"),
            ("sep/sep_parser.py 0006", "Parsing SEP-06 (Deposit and Withdrawal API) specification", "sep"),
            ("sep/sep_analyzer.py 0006", "Analyzing SEP-06 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0006", "Generating SEP-06 compatibility report", "sep"),
            ("sep/sep_parser.py 0007", "Parsing SEP-07 (URI Scheme) specification", "sep"),
            ("sep/sep_analyzer.py 0007", "Analyzing SEP-07 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0007", "Generating SEP-07 compatibility report", "sep"),
            ("sep/sep_parser.py 0008", "Parsing SEP-08 (Regulated Assets) specification", "sep"),
            ("sep/sep_analyzer.py 0008", "Analyzing SEP-08 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0008", "Generating SEP-08 compatibility report", "sep"),
            ("sep/sep_parser.py 0009", "Parsing SEP-09 (Standard KYC/AML fields) specification", "sep"),
            ("sep/sep_analyzer.py 0009", "Analyzing SEP-09 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0009", "Generating SEP-09 compatibility report", "sep"),
            ("sep/sep_parser.py 0010", "Parsing SEP-10 (Web Auth) specification", "sep"),
            ("sep/sep_analyzer.py 0010", "Analyzing SEP-10 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0010", "Generating SEP-10 compatibility report", "sep"),
            ("sep/sep_parser.py 0011", "Parsing SEP-11 (Txrep) specification", "sep"),
            ("sep/sep_analyzer.py 0011", "Analyzing SEP-11 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0011", "Generating SEP-11 compatibility report", "sep"),
            ("sep/sep_parser.py 0012", "Parsing SEP-12 (KYC API) specification", "sep"),
            ("sep/sep_analyzer.py 0012", "Analyzing SEP-12 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0012", "Generating SEP-12 compatibility report", "sep"),
            ("sep/sep_parser.py 0024", "Parsing SEP-24 (Hosted Deposit/Withdrawal) specification", "sep"),
            ("sep/sep_analyzer.py 0024", "Analyzing SEP-24 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0024", "Generating SEP-24 compatibility report", "sep"),
            ("sep/sep_parser.py 0030", "Parsing SEP-30 (Account Recovery) specification", "sep"),
            ("sep/sep_analyzer.py 0030", "Analyzing SEP-30 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0030", "Generating SEP-30 compatibility report", "sep"),
            ("sep/sep_parser.py 0038", "Parsing SEP-38 (Anchor RFQ API) specification", "sep"),
            ("sep/sep_analyzer.py 0038", "Analyzing SEP-38 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0038", "Generating SEP-38 compatibility report", "sep"),
            ("sep/sep_parser.py 0045", "Parsing SEP-45 (Web Auth for Contract Accounts) specification", "sep"),
            ("sep/sep_analyzer.py 0045", "Analyzing SEP-45 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0045", "Generating SEP-45 compatibility report", "sep"),
            ("sep/sep_parser.py 0046", "Parsing SEP-46 (Contract Meta) specification", "sep"),
            ("sep/sep_analyzer.py 0046", "Analyzing SEP-46 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0046", "Generating SEP-46 compatibility report", "sep"),
            ("sep/sep_parser.py 0047", "Parsing SEP-47 (Contract Interface Discovery) specification", "sep"),
            ("sep/sep_analyzer.py 0047", "Analyzing SEP-47 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0047", "Generating SEP-47 compatibility report", "sep"),
            ("sep/sep_parser.py 0048", "Parsing SEP-48 (Smart Contract Specifications) specification", "sep"),
            ("sep/sep_analyzer.py 0048", "Analyzing SEP-48 implementation in SDK", "sep"),
            ("sep/generate_sep_comparison.py 0048", "Generating SEP-48 compatibility report", "sep"),
        ]
        self.results: List[Tuple[str, bool, str]] = []

    def print_header(self):
        """Print analysis header"""
        print(f"\n{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}")
        print(f"{Colors.BOLD}{Colors.HEADER}Flutter Stellar SDK - Compatibility Analysis{Colors.END}")
        print(f"{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}\n")
        print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

    def print_step(self, step_num: int, total: int, description: str):
        """Print step header"""
        print(f"\n{Colors.BOLD}{Colors.CYAN}[{step_num}/{total}] {description}{Colors.END}")
        print(f"{Colors.CYAN}{'-' * 70}{Colors.END}")

    def run_script(self, script_name: str, description: str, category: str) -> Tuple[bool, str]:
        """
        Run a single script and capture output

        Args:
            script_name: Name of the script to run (may include arguments)
            description: Description of what the script does
            category: Category (horizon, rpc, or sep)

        Returns:
            Tuple of (success, output)
        """
        # Split script name and arguments
        parts = script_name.split()
        script_file = parts[0]
        script_args = parts[1:] if len(parts) > 1 else []

        script_path = self.tools_dir / script_file

        if not script_path.exists():
            return False, f"Script not found: {script_path}"

        try:
            # Run script with arguments
            result = subprocess.run(
                [sys.executable, str(script_path)] + script_args,
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )

            # Check exit code
            if result.returncode == 0:
                return True, result.stdout
            else:
                error_msg = result.stderr if result.stderr else result.stdout
                return False, f"Script failed with exit code {result.returncode}:\n{error_msg}"

        except subprocess.TimeoutExpired:
            return False, "Script execution timed out (5 minutes)"
        except Exception as e:
            return False, f"Error running script: {str(e)}"

    def run_all(self) -> bool:
        """
        Run all analysis scripts in sequence

        Returns:
            True if all scripts succeeded, False otherwise
        """
        self.print_header()

        total_steps = len(self.scripts)
        all_success = True

        for step_num, (script_name, description, category) in enumerate(self.scripts, 1):
            self.print_step(step_num, total_steps, description)

            # Run script
            success, output = self.run_script(script_name, description, category)

            # Store result
            self.results.append((description, success, output))

            # Print result
            if success:
                print(f"{Colors.GREEN}✓ {description} completed successfully{Colors.END}")
                # Print relevant output lines
                for line in output.split('\n'):
                    if 'Total' in line or 'Coverage' in line or 'Saved' in line or '✓' in line:
                        print(f"  {line}")
            else:
                print(f"{Colors.RED}✗ {description} failed{Colors.END}")
                print(f"{Colors.RED}{output}{Colors.END}")
                all_success = False

                # Stop on first failure for critical pipeline scripts
                if script_name in ['horizon/run_horizon_analysis.py', 'rpc/run_rpc_analysis.py']:
                    print(f"\n{Colors.YELLOW}Stopping analysis due to critical script failure{Colors.END}")
                    break

        return all_success

    def print_summary(self):
        """Print final summary"""
        print(f"\n{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}")
        print(f"{Colors.BOLD}{Colors.HEADER}Analysis Summary{Colors.END}")
        print(f"{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}\n")

        success_count = sum(1 for _, success, _ in self.results if success)
        total_count = len(self.results)

        print(f"Completed: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        print(f"Results: {success_count}/{total_count} scripts succeeded\n")

        for description, success, _ in self.results:
            icon = f"{Colors.GREEN}✓{Colors.END}" if success else f"{Colors.RED}✗{Colors.END}"
            print(f"  {icon} {description}")

        print(f"\n{Colors.BOLD}Generated Reports:{Colors.END}\n")

        # Build report list programmatically
        reports = [
            ("Horizon Endpoints", "tools/matrix-generator/data/horizon/horizon_endpoints.json"),
            ("Flutter SDK Implementation", "tools/matrix-generator/data/horizon/flutter_sdk_implementation.json"),
            ("Horizon Compatibility Matrix", "compatibility/horizon/HORIZON_COMPATIBILITY_MATRIX.md"),
            ("Horizon Coverage Statistics", "tools/matrix-generator/data/horizon/coverage_stats.json"),
            ("RPC Methods", "tools/matrix-generator/data/rpc/rpc_methods.json"),
            ("Flutter Soroban Implementation", "tools/matrix-generator/data/rpc/flutter_soroban_implementation.json"),
            ("RPC Compatibility Matrix", "compatibility/rpc/RPC_COMPATIBILITY_MATRIX.md"),
            ("RPC Coverage Statistics", "tools/matrix-generator/data/rpc/rpc_coverage_stats.json"),
        ]

        # Extract SEP numbers from the scripts list
        sep_numbers = sorted(set(
            parts[1] for script, _, _ in self.scripts
            if (parts := script.split()) and parts[0] == "sep/sep_parser.py" and len(parts) > 1
        ))
        for sep in sep_numbers:
            sep_label = f"SEP-{int(sep):02d}"
            reports.extend([
                (f"{sep_label} Definition", f"tools/matrix-generator/data/sep/sep_{sep}_definition.json"),
                (f"{sep_label} SDK Implementation", f"tools/matrix-generator/data/sep/flutter_sep_{sep}_implementation.json"),
                (f"{sep_label} Compatibility Matrix", f"compatibility/sep/SEP-{sep}_COMPATIBILITY_MATRIX.md"),
                (f"{sep_label} Coverage Statistics", f"tools/matrix-generator/data/sep/sep_{sep}_coverage_stats.json"),
            ])

        for report_name, report_path in reports:
            full_path = self.base_dir / report_path
            if full_path.exists():
                print(f"  {Colors.GREEN}✓{Colors.END} {report_name}")
                print(f"    {Colors.CYAN}{full_path}{Colors.END}")
            else:
                print(f"  {Colors.YELLOW}⚠{Colors.END} {report_name} (not generated)")

        print()

        # Overall result
        if success_count == total_count:
            print(f"{Colors.BOLD}{Colors.GREEN}{'=' * 70}{Colors.END}")
            print(f"{Colors.BOLD}{Colors.GREEN}All analyses completed successfully!{Colors.END}")
            print(f"{Colors.BOLD}{Colors.GREEN}{'=' * 70}{Colors.END}\n")
        else:
            print(f"{Colors.BOLD}{Colors.YELLOW}{'=' * 70}{Colors.END}")
            print(f"{Colors.BOLD}{Colors.YELLOW}Some analyses failed. Review errors above.{Colors.END}")
            print(f"{Colors.BOLD}{Colors.YELLOW}{'=' * 70}{Colors.END}\n")

    def verify_prerequisites(self) -> Tuple[bool, List[str]]:
        """
        Verify that all prerequisites are met

        Returns:
            Tuple of (success, list of error messages)
        """
        errors = []

        # Check if stellar-go repository exists (sibling of SDK root)
        stellar_go = SDK_ROOT.parent / "stellar-go"
        if not stellar_go.exists():
            errors.append(f"stellar-go repository not found at {stellar_go}")
        else:
            router_go = stellar_go / "services/horizon/internal/httpx/router.go"
            if not router_go.exists():
                errors.append(f"Horizon router.go not found at {router_go}")

        # Check if stellar-rpc repository exists (sibling of SDK root)
        stellar_rpc = SDK_ROOT.parent / "stellar-rpc"
        if not stellar_rpc.exists():
            errors.append(f"stellar-rpc repository not found at {stellar_rpc}")

        # Check if Flutter SDK files exist
        sdk_main = self.base_dir / "lib/src/stellar_sdk.dart"
        if not sdk_main.exists():
            errors.append(f"Flutter SDK main file not found at {sdk_main}")

        requests_dir = self.base_dir / "lib/src/requests"
        if not requests_dir.exists():
            errors.append(f"Flutter SDK requests directory not found at {requests_dir}")

        soroban_server = self.base_dir / "lib/src/soroban/soroban_server.dart"
        if not soroban_server.exists():
            errors.append(f"Flutter SDK Soroban server not found at {soroban_server}")

        # Check Python version
        if sys.version_info < (3, 8):
            errors.append(f"Python 3.8+ required, found {sys.version_info.major}.{sys.version_info.minor}")

        return len(errors) == 0, errors


def main():
    """Main entry point"""
    # Check if we're in a TTY (for colors)
    if not sys.stdout.isatty():
        Colors.disable()

    orchestrator = AnalysisOrchestrator()

    # Verify prerequisites
    prereq_ok, errors = orchestrator.verify_prerequisites()
    if not prereq_ok:
        print(f"{Colors.RED}ERROR: Prerequisites not met:{Colors.END}\n")
        for error in errors:
            print(f"  {Colors.RED}✗{Colors.END} {error}")
        print(f"\n{Colors.YELLOW}Please ensure all required repositories are cloned and paths are correct.{Colors.END}")
        return 1

    # Run all analyses
    success = orchestrator.run_all()

    # Print summary
    orchestrator.print_summary()

    return 0 if success else 1


if __name__ == '__main__':
    sys.exit(main())
