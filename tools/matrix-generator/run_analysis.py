#!/usr/bin/env python3
"""
Compatibility Analysis Orchestrator

Runs all compatibility analysis scripts in sequence with colored terminal output.

Author: Stellar Flutter SDK Team
License: Apache-2.0
"""

import sys
import subprocess
from pathlib import Path
from typing import List, Tuple
from datetime import datetime

from common import Colors, SDK_ROOT


# SEPs in run order, with the name the step descriptions give them.
SEPS = (
    ('0001', 'stellar.toml'),
    ('0002', 'Federation'),
    ('0005', 'Key Derivation'),
    ('0006', 'Deposit and Withdrawal API'),
    ('0007', 'URI Scheme'),
    ('0008', 'Regulated Assets'),
    ('0009', 'Standard KYC/AML fields'),
    ('0010', 'Web Auth'),
    ('0011', 'Txrep'),
    ('0012', 'KYC API'),
    ('0023', 'Strkeys'),
    ('0024', 'Hosted Deposit/Withdrawal'),
    ('0029', 'Account Memo Requirements'),
    ('0030', 'Account Recovery'),
    ('0038', 'Anchor RFQ API'),
    ('0045', 'Web Auth for Contract Accounts'),
    ('0046', 'Contract Meta'),
    ('0047', 'Contract Interface Discovery'),
    ('0048', 'Smart Contract Specifications'),
    ('0051', 'XDR-JSON'),
    ('0053', 'Sign and Verify Messages'),
)


class AnalysisOrchestrator:
    """Orchestrates the execution of all analysis scripts"""

    def __init__(self):
        """Initialize orchestrator"""
        self.tools_dir = Path(__file__).parent
        self.base_dir = self.tools_dir.parent.parent  # Go up two levels to SDK root
        self.scripts: List[Tuple[str, str]] = [
            ("horizon/run_horizon_analysis.py", "Generating Horizon compatibility report"),
            ("rpc/run_rpc_analysis.py", "Generating RPC compatibility report"),
        ]
        for number, name in SEPS:
            label = f"SEP-{number[2:]}"
            self.scripts += [
                (f"sep/sep_parser.py {number}", f"Parsing {label} ({name}) specification"),
                (f"sep/sep_analyzer.py {number}", f"Analyzing {label} implementation in SDK"),
                (f"sep/generate_sep_comparison.py {number}", f"Generating {label} compatibility report"),
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

    def run_script(self, script_name: str) -> Tuple[bool, str]:
        """
        Run a single script and capture output

        Args:
            script_name: Name of the script to run (may include arguments)

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
        Run all analysis scripts in sequence, stopping at the first failure

        Returns:
            True if all scripts succeeded, False otherwise
        """
        self.print_header()

        total_steps = len(self.scripts)
        all_success = True

        for step_num, (script_name, description) in enumerate(self.scripts, 1):
            self.print_step(step_num, total_steps, description)

            # Run script
            success, output = self.run_script(script_name)

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
                # Later stages read the files earlier stages write.
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

        for sep, _ in SEPS:
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

        # Check if stellar-horizon repository exists (sibling of SDK root).
        # Endpoint definitions sit at internal/httpx/router.go, relative to the
        # repository root.
        stellar_horizon = SDK_ROOT.parent / "stellar-horizon"
        if not stellar_horizon.exists():
            errors.append(f"stellar-horizon repository not found at {stellar_horizon}")
        else:
            router_go = stellar_horizon / "internal/httpx/router.go"
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
