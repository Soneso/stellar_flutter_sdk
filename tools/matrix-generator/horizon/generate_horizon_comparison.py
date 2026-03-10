#!/usr/bin/env python3
"""
Horizon API vs Flutter SDK Compatibility Comparison Generator

This script compares the official Horizon API endpoints with the Flutter SDK implementation
and generates detailed compatibility reports, statistics, and markdown documentation.

Author: Stellar Flutter SDK Team
License: Apache-2.0
"""

import json
import sys
import traceback
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Tuple, Optional
from dataclasses import dataclass
from enum import Enum


class CompatibilityStatus(Enum):
    """Compatibility status indicators"""
    FULLY_SUPPORTED = "✅"
    PARTIALLY_SUPPORTED = "⚠️"
    NOT_SUPPORTED = "❌"
    DEPRECATED = "🔄"


class GapPriority(Enum):
    """Priority levels for implementation gaps"""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


@dataclass
class EndpointComparison:
    """Represents a comparison between a Horizon endpoint and SDK implementation"""
    category: str
    horizon_endpoint: Dict[str, Any]
    sdk_implementation: Dict[str, Any]
    status: str
    notes: str
    missing_features: List[str]
    priority: Optional[str] = None


class HorizonSDKComparator:
    """Main class for comparing Horizon API with Flutter SDK implementation"""

    def __init__(self, horizon_data_path: str, sdk_data_path: str):
        """
        Initialize the comparator with data file paths.

        Args:
            horizon_data_path: Path to horizon_endpoints.json
            sdk_data_path: Path to flutter_sdk_implementation.json
        """
        self.horizon_data_path = Path(horizon_data_path)
        self.sdk_data_path = Path(sdk_data_path)
        self.horizon_data: Dict[str, Any] = {}
        self.sdk_data: Dict[str, Any] = {}
        self.comparisons: List[EndpointComparison] = []
        self.horizon_version: str = "Unknown"
        self.horizon_release_date: str = "Unknown"
        self.horizon_release_url: str = ""

    def load_data(self) -> None:
        """Load JSON data from both files and extract version information"""
        print("Loading Horizon API endpoints data...")
        with open(self.horizon_data_path, 'r', encoding='utf-8') as f:
            self.horizon_data = json.load(f)

        print("Loading Flutter SDK implementation data...")
        with open(self.sdk_data_path, 'r', encoding='utf-8') as f:
            self.sdk_data = json.load(f)

        # Extract Horizon version information from metadata
        metadata = self.horizon_data.get('metadata', {})
        self.horizon_version = metadata.get('horizon_version', 'Unknown')
        self.horizon_release_date = metadata.get('horizon_release_date', 'Unknown')
        self.horizon_release_url = metadata.get('horizon_release_url', '')

        print(f"Loaded {self.horizon_data['metadata']['total_endpoints']} Horizon endpoints")
        print(f"Horizon version: {self.horizon_version}")
        print(f"Loaded {self.sdk_data['metadata']['total_request_builders']} SDK request builders")

    def normalize_endpoint_path(self, path: str) -> str:
        """
        Normalize endpoint path for comparison.

        Args:
            path: Endpoint path (e.g., '/accounts/{account_id}')

        Returns:
            Normalized path
        """
        normalized = path

        # Replace different parameter formats
        normalized = normalized.replace('{tx_id}', '{transaction_id}')
        normalized = normalized.replace('{op_id}', '{operation_id}')
        normalized = normalized.replace('{ledger_id}', '{ledger_sequence}')
        normalized = normalized.replace('{sequence}', '{ledger_sequence}')

        # Context-aware {id} replacement
        if '/operations/{id}' in normalized:
            normalized = normalized.replace('/operations/{id}', '/operations/{operation_id}')
        elif '/claimable_balances/{id}' in normalized:
            normalized = normalized.replace('/claimable_balances/{id}', '/claimable_balances/{claimable_balance_id}')
        elif '/liquidity_pools/{id}' in normalized:
            normalized = normalized.replace('/liquidity_pools/{id}', '/liquidity_pools/{liquidity_pool_id}')
        elif '/offers/{id}' in normalized:
            normalized = normalized.replace('/offers/{id}', '/offers/{offer_id}')

        return normalized

    # Endpoints that can be served by alternative builders with full filter support
    # Maps endpoint -> (alternative_endpoint, filter_that_covers_path_param, sdk_method_override, notes)
    ENDPOINT_ALTERNATIVES = {
        '/liquidity_pools/{liquidity_pool_id}/trades': (
            '/trades',
            'liquidity_pool_id',
            'trades.liquidityPoolId',
            'Fully supported via TradesRequestBuilder.liquidityPoolId()'
        ),
    }

    def find_sdk_implementation(self, endpoint_path: str, method: str) -> Tuple[bool, Dict[str, Any]]:
        """
        Find SDK implementation for a given endpoint.

        Args:
            endpoint_path: Horizon endpoint path
            method: HTTP method (GET, POST, etc.)

        Returns:
            Tuple of (found, implementation_details)
        """
        sdk_methods = self.sdk_data.get('sdk_methods', {})

        # Try exact match first
        lookup_key = endpoint_path
        if method == 'POST':
            lookup_key = f"{endpoint_path} ({method})"

        if lookup_key in sdk_methods:
            impl = sdk_methods[lookup_key]
            result = {
                'implemented': impl.get('implemented', False),
                'sdk_method': impl.get('sdk_method', ''),
                'class': impl.get('class', ''),
                'streaming': impl.get('streaming', False),
                'deprecated': impl.get('deprecated', False),
                'filters': impl.get('filters', []),
                'notes': impl.get('notes', '')
            }

            # Check if there's an alternative with better filter support
            if endpoint_path in self.ENDPOINT_ALTERNATIVES:
                alt_endpoint, alt_filter, alt_sdk_method, alt_notes = self.ENDPOINT_ALTERNATIVES[endpoint_path]
                if alt_endpoint in sdk_methods:
                    alt_impl = sdk_methods[alt_endpoint]
                    alt_filters = alt_impl.get('filters', [])
                    # If alternative has the required filter and more filters overall
                    if alt_filter in alt_filters and len(alt_filters) > len(result['filters']):
                        result['filters'] = alt_filters
                        result['notes'] = alt_notes
                        result['class'] = alt_impl.get('class', result['class'])
                        result['sdk_method'] = alt_sdk_method  # Use the explicit SDK method override
                        result['streaming'] = alt_impl.get('streaming', result['streaming'])

            return True, result

        return False, {}

    def check_parameter_support(self, horizon_params: List[Dict], sdk_impl: Dict[str, Any]) -> List[str]:
        """
        Check which parameters are missing in SDK implementation.

        Args:
            horizon_params: List of parameters from Horizon API
            sdk_impl: SDK implementation details

        Returns:
            List of missing parameters
        """
        if not sdk_impl or not horizon_params:
            return []

        # Common pagination parameters are always supported
        standard_params = {'cursor', 'limit', 'order'}

        # Path parameters are handled by method arguments
        path_params = {'account_id', 'ledger_id', 'ledger_sequence', 'transaction_id',
                      'tx_id', 'operation_id', 'op_id', 'claimable_balance_id',
                      'liquidity_pool_id', 'offer_id', 'key', 'id', 'sequence'}

        # SDK composite filters that cover multiple Horizon parameters
        # The SDK uses cleaner Asset objects instead of separate type/code/issuer params
        composite_filters = {
            'base_asset': ['base_asset_type', 'base_asset_code', 'base_asset_issuer'],
            'counter_asset': ['counter_asset_type', 'counter_asset_code', 'counter_asset_issuer'],
            'selling_asset': ['selling_asset_type', 'selling_asset_code', 'selling_asset_issuer'],
            'buying_asset': ['buying_asset_type', 'buying_asset_code', 'buying_asset_issuer'],
            'asset': ['asset_type', 'asset_code', 'asset_issuer'],
            # account_id filter covers "account" parameter
            'account_id': ['account'],
            # reserves filter covers "reserves" parameter
            'reserves': ['reserves'],
            # trade_type filter covers "type" parameter for trades
            'trade_type': ['type'],
        }

        missing = []
        sdk_filters = set(sdk_impl.get('filters', []))

        # Special case: Transaction submission POST endpoints accept tx parameter via method argument
        # not as a filter
        if sdk_impl.get('class') == 'StellarSDK' and sdk_impl.get('sdk_method') in [
            'submitTransactionEnvelopeXdrBase64', 'submitAsyncTransactionEnvelopeXdrBase64'
        ]:
            # The tx parameter is passed as a method argument (the transaction envelope XDR),
            # not as a filter. Mark it as supported.
            sdk_filters = sdk_filters.union({'tx'})

        # Special case: TradeAggregationsRequestBuilder accepts parameters via constructor
        # rather than filter methods
        if sdk_impl.get('class') == 'TradeAggregationsRequestBuilder':
            # Add constructor parameters to the supported filters
            constructor_params = {
                'start_time', 'end_time', 'resolution', 'offset',
                'base_asset_type', 'base_asset_code', 'base_asset_issuer',
                'counter_asset_type', 'counter_asset_code', 'counter_asset_issuer'
            }
            sdk_filters = sdk_filters.union(constructor_params)

        # Build a set of all Horizon params covered by SDK composite filters
        covered_by_composite = set()
        for sdk_filter in sdk_filters:
            if sdk_filter in composite_filters:
                covered_by_composite.update(composite_filters[sdk_filter])

        for param in horizon_params:
            param_name = param.get('name', param) if isinstance(param, dict) else param

            # Skip standard pagination params
            if param_name in standard_params:
                continue

            # Skip path parameters
            if param_name in path_params:
                continue

            # Check if parameter is directly supported via filters
            if param_name in sdk_filters:
                continue

            # Check if parameter is covered by a composite filter
            if param_name in covered_by_composite:
                continue

            # Parameter is not supported
            missing.append(param_name)

        return missing

    def determine_status(self, endpoint: Dict[str, Any], sdk_impl: Dict[str, Any],
                        missing_features: List[str]) -> CompatibilityStatus:
        """
        Determine the compatibility status of an endpoint.

        Args:
            endpoint: Horizon endpoint details
            sdk_impl: SDK implementation details
            missing_features: List of missing features

        Returns:
            CompatibilityStatus enum value
        """
        if not sdk_impl:
            return CompatibilityStatus.NOT_SUPPORTED

        if sdk_impl.get('deprecated', False):
            return CompatibilityStatus.DEPRECATED

        if not sdk_impl.get('implemented', False):
            return CompatibilityStatus.NOT_SUPPORTED

        # Check streaming support mismatch
        streaming_mismatch = (endpoint.get('streaming', False) and
                            not sdk_impl.get('streaming', False))

        # Determine status based on missing features
        if missing_features or streaming_mismatch:
            return CompatibilityStatus.PARTIALLY_SUPPORTED

        return CompatibilityStatus.FULLY_SUPPORTED

    def determine_priority(self, endpoint: Dict[str, Any], status: CompatibilityStatus) -> Optional[str]:
        """
        Determine implementation priority for gaps.

        Args:
            endpoint: Horizon endpoint details
            status: Current compatibility status

        Returns:
            Priority level string or None
        """
        if status == CompatibilityStatus.FULLY_SUPPORTED:
            return None

        # Critical: Core functionality
        core_endpoints = {
            '/accounts/{account_id}',
            '/transactions',
            '/operations',
            '/ledgers'
        }

        if endpoint['path'] in core_endpoints:
            if status == CompatibilityStatus.NOT_SUPPORTED:
                return GapPriority.CRITICAL.value
            return GapPriority.HIGH.value

        # High: Commonly used features
        common_endpoints = {
            '/payments',
            '/effects',
            '/transactions/{transaction_id}',
            '/order_book',
            '/paths/strict-receive',
            '/paths/strict-send'
        }

        if endpoint['path'] in common_endpoints:
            if status == CompatibilityStatus.NOT_SUPPORTED:
                return GapPriority.HIGH.value
            return GapPriority.MEDIUM.value

        # Medium: Advanced features
        category_path = endpoint['path'].split('/')[1] if '/' in endpoint['path'] else ''
        if category_path in ['trade_aggregations', 'liquidity_pools', 'claimable_balances']:
            if status == CompatibilityStatus.NOT_SUPPORTED:
                return GapPriority.MEDIUM.value
            return GapPriority.LOW.value

        # Low: Nice to have features
        if status == CompatibilityStatus.NOT_SUPPORTED:
            return GapPriority.MEDIUM.value

        return GapPriority.LOW.value

    def compare_endpoints(self) -> None:
        """Compare all Horizon endpoints with SDK implementation"""
        print("\nComparing endpoints...")

        # Define endpoints to ignore - these exist in Horizon but are deprecated/undocumented
        # or are test-only utilities that should not appear in the compatibility matrix
        ignored_endpoints = {
            '/paths',  # Deprecated alias for /paths/strict-receive
        }

        # Specific endpoint+method combinations to ignore
        ignored_endpoint_methods = {
            ('POST', '/friendbot'),  # Redundant, GET is used instead
        }

        categories = self.horizon_data.get('categories', {})

        for category_name, category_data in categories.items():
            endpoints = category_data.get('endpoints', [])

            for endpoint in endpoints:
                path = endpoint['path']
                method = endpoint['method']

                # Skip ignored endpoints
                if path in ignored_endpoints:
                    print(f"  Skipping deprecated/ignored endpoint: {method} {path}")
                    continue

                # Skip specific method+endpoint combinations
                if (method, path) in ignored_endpoint_methods:
                    print(f"  Skipping redundant endpoint: {method} {path}")
                    continue
                normalized_path = self.normalize_endpoint_path(path)

                # Find SDK implementation
                found, sdk_impl = self.find_sdk_implementation(normalized_path, method)

                # Check for missing parameters/features
                missing_features = []
                if found and sdk_impl.get('implemented', False):
                    missing_params = self.check_parameter_support(
                        endpoint.get('parameters', []),
                        sdk_impl
                    )
                    if missing_params:
                        missing_features.extend([f"Parameter: {p}" for p in missing_params])

                    # Check streaming support
                    if endpoint.get('streaming', False) and not sdk_impl.get('streaming', False):
                        missing_features.append("Streaming support")

                # Determine status
                status = self.determine_status(endpoint, sdk_impl, missing_features)

                # Generate notes
                notes = self._generate_notes(endpoint, sdk_impl, status)

                # Determine priority
                priority = self.determine_priority(endpoint, status)

                # Create comparison
                comparison = EndpointComparison(
                    category=category_name,
                    horizon_endpoint={
                        'method': method,
                        'path': path,
                        'streaming': endpoint.get('streaming', False),
                        'description': endpoint.get('description', ''),
                        'parameters': [p.get('name', p) if isinstance(p, dict) else p
                                     for p in endpoint.get('parameters', [])]
                    },
                    sdk_implementation={
                        'implemented': sdk_impl.get('implemented', False) if sdk_impl else False,
                        'sdk_method': sdk_impl.get('sdk_method', '') if sdk_impl else '',
                        'class': sdk_impl.get('class', '') if sdk_impl else '',
                        'streaming': sdk_impl.get('streaming', False) if sdk_impl else False,
                        'deprecated': sdk_impl.get('deprecated', False) if sdk_impl else False
                    },
                    status=status.value,
                    notes=notes,
                    missing_features=missing_features,
                    priority=priority
                )

                self.comparisons.append(comparison)

        print(f"Compared {len(self.comparisons)} endpoints")

    def _generate_notes(self, endpoint: Dict[str, Any], sdk_impl: Dict[str, Any],
                       status: CompatibilityStatus) -> str:
        """Generate detailed notes about the comparison"""
        notes = []

        if status == CompatibilityStatus.NOT_SUPPORTED:
            notes.append("Endpoint not implemented in SDK")
            if endpoint.get('description'):
                notes.append(f"Horizon: {endpoint['description']}")

        elif status == CompatibilityStatus.DEPRECATED:
            notes.append("Deprecated endpoint with newer alternative available")
            if sdk_impl.get('notes'):
                notes.append(sdk_impl['notes'])

        elif status == CompatibilityStatus.PARTIALLY_SUPPORTED:
            notes.append("Basic functionality implemented but with limitations")

        elif status == CompatibilityStatus.FULLY_SUPPORTED:
            notes.append("Full implementation with all features supported")

        # Add SDK-specific notes
        if sdk_impl and sdk_impl.get('notes'):
            notes.append(sdk_impl['notes'])

        return ". ".join(notes)

    def calculate_statistics(self) -> Dict[str, Any]:
        """Calculate coverage statistics from comparisons"""
        print("\nCalculating statistics...")

        total = len(self.comparisons)
        status_counts = {
            'fully_supported': 0,
            'partially_supported': 0,
            'not_supported': 0,
            'deprecated': 0
        }

        category_stats = {}
        streaming_stats = {
            'total_streaming_endpoints': 0,
            'supported': 0
        }

        gaps_by_priority = {
            GapPriority.CRITICAL.value: [],
            GapPriority.HIGH.value: [],
            GapPriority.MEDIUM.value: [],
            GapPriority.LOW.value: []
        }

        for comp in self.comparisons:
            # Count by status
            if comp.status == CompatibilityStatus.FULLY_SUPPORTED.value:
                status_counts['fully_supported'] += 1
            elif comp.status == CompatibilityStatus.PARTIALLY_SUPPORTED.value:
                status_counts['partially_supported'] += 1
            elif comp.status == CompatibilityStatus.NOT_SUPPORTED.value:
                status_counts['not_supported'] += 1
            elif comp.status == CompatibilityStatus.DEPRECATED.value:
                status_counts['deprecated'] += 1

            # Category statistics
            if comp.category not in category_stats:
                category_stats[comp.category] = {
                    'total': 0,
                    'supported': 0
                }
            category_stats[comp.category]['total'] += 1
            if comp.status in [CompatibilityStatus.FULLY_SUPPORTED.value,
                             CompatibilityStatus.PARTIALLY_SUPPORTED.value]:
                category_stats[comp.category]['supported'] += 1

            # Streaming statistics
            if comp.horizon_endpoint.get('streaming', False):
                streaming_stats['total_streaming_endpoints'] += 1
                if comp.sdk_implementation.get('streaming', False):
                    streaming_stats['supported'] += 1

            # Gaps by priority
            if comp.priority:
                gaps_by_priority[comp.priority].append({
                    'endpoint': comp.horizon_endpoint['path'],
                    'category': comp.category,
                    'status': comp.status,
                    'notes': comp.notes
                })

        # Calculate percentages
        coverage_percentage = round(
            (status_counts['fully_supported'] / total * 100) if total > 0 else 0, 2
        )

        for category, stats in category_stats.items():
            stats['percentage'] = round(
                (stats['supported'] / stats['total'] * 100) if stats['total'] > 0 else 0, 2
            )

        streaming_stats['percentage'] = round(
            (streaming_stats['supported'] / streaming_stats['total_streaming_endpoints'] * 100)
            if streaming_stats['total_streaming_endpoints'] > 0 else 0, 2
        )

        return {
            'overall': {
                'total_endpoints': total,
                'fully_supported': status_counts['fully_supported'],
                'partially_supported': status_counts['partially_supported'],
                'not_supported': status_counts['not_supported'],
                'deprecated': status_counts['deprecated'],
                'coverage_percentage': coverage_percentage
            },
            'by_category': category_stats,
            'streaming': streaming_stats,
            'gaps_summary': gaps_by_priority
        }

    def generate_markdown_report(self, output_path: str) -> None:
        """Generate detailed markdown compatibility matrix"""
        print(f"\nGenerating markdown report: {output_path}")

        stats = self.calculate_statistics()
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)

        with open(output_file, 'w', encoding='utf-8') as f:
            # Header
            f.write("# Horizon API vs Flutter SDK Compatibility Matrix\n\n")

            # Horizon Version Information
            horizon_version_display = self.horizon_version
            if self.horizon_release_date != "Unknown":
                horizon_version_display += f" (released {self.horizon_release_date})"

            f.write(f"**Horizon Version:** {horizon_version_display}  \n")
            if self.horizon_release_url:
                f.write(f"**Horizon Source:** [{self.horizon_version}]({self.horizon_release_url})  \n")
            f.write(f"**SDK Version:** {self.sdk_data['metadata']['sdk_version']}  \n")
            f.write(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

            # Get overall stats first
            overall = stats['overall']

            # Show total discovered vs public API endpoints
            total_discovered = self.horizon_data['metadata']['total_endpoints']
            total_in_matrix = overall['total_endpoints']
            excluded_count = total_discovered - total_in_matrix

            f.write(f"**Horizon Endpoints Discovered:** {total_discovered}  \n")
            f.write(f"**Public API Endpoints (in matrix):** {total_in_matrix}\n\n")

            # Add explanation if there are excluded endpoints
            if excluded_count > 0:
                plural = 's' if excluded_count != 1 else ''
                verb = 'are' if excluded_count != 1 else 'is'
                f.write(f"> **Note:** {excluded_count} endpoint{plural} {verb} intentionally excluded from the matrix:\n")
                f.write("> - `GET /paths` - Deprecated (replaced by `/paths/strict-receive` and `/paths/strict-send`)\n")
                f.write("> - `POST /friendbot` - Redundant (GET method is used instead)\n\n")

            # Overall Statistics
            f.write("## Overall Coverage\n\n")
            f.write(f"**Coverage:** {overall['coverage_percentage']}% ({overall['fully_supported']}/{overall['total_endpoints']} public API endpoints)\n\n")
            f.write(f"- ✅ **Fully Supported:** {overall['fully_supported']}/{overall['total_endpoints']}\n")
            f.write(f"- ⚠️ **Partially Supported:** {overall['partially_supported']}/{overall['total_endpoints']}\n")
            f.write(f"- ❌ **Not Supported:** {overall['not_supported']}/{overall['total_endpoints']}\n")
            f.write(f"- 🔄 **Deprecated:** {overall['deprecated']}/{overall['total_endpoints']}\n\n")

            # Category Breakdown
            f.write("## Coverage by Category\n\n")
            f.write("| Category | Coverage | Supported | Not Supported | Total |\n")
            f.write("|----------|----------|-----------|---------------|-------|\n")
            for category in sorted(stats['by_category'].keys()):
                cat_stats = stats['by_category'][category]
                # Display "root" for empty category (the / endpoint)
                display_category = category if category else "root"
                not_supported = cat_stats['total'] - cat_stats['supported']
                f.write(f"| {display_category} | {cat_stats['percentage']}% | "
                       f"{cat_stats['supported']} | {not_supported} | {cat_stats['total']} |\n")
            f.write("\n")

            # Streaming Support
            streaming = stats['streaming']
            f.write("## Streaming Support\n\n")
            f.write(f"**Coverage:** {streaming['percentage']}%\n\n")
            f.write(f"- Streaming endpoints: {streaming['total_streaming_endpoints']}\n")
            f.write(f"- Supported: {streaming['supported']}\n\n")

            # Detailed Endpoint Comparison
            f.write("## Detailed Endpoint Comparison\n\n")

            # Group by category
            by_category = {}
            for comp in self.comparisons:
                if comp.category not in by_category:
                    by_category[comp.category] = []
                by_category[comp.category].append(comp)

            for category in sorted(by_category.keys()):
                # Display "Root" for empty category (the / endpoint)
                display_category = category.title() if category else "Root"
                f.write(f"### {display_category}\n\n")
                f.write("| Endpoint | Method | Status | SDK Method | Streaming | Notes |\n")
                f.write("|----------|--------|--------|------------|-----------|-------|\n")

                for comp in sorted(by_category[category], key=lambda x: x.horizon_endpoint['path']):
                    endpoint = comp.horizon_endpoint
                    sdk = comp.sdk_implementation

                    streaming_icon = "✓" if sdk.get('streaming') else ""
                    sdk_method = sdk.get('sdk_method', '-')

                    # Don't truncate notes - let the markdown renderer handle wrapping
                    notes = comp.notes

                    f.write(f"| `{endpoint['path']}` | {endpoint['method']} | "
                           f"{comp.status} | `{sdk_method}` | {streaming_icon} | {notes} |\n")

                f.write("\n")

            # Implementation Gaps - only show if there are gaps
            total_gaps = sum(len(stats['gaps_summary'][p]) for p in stats['gaps_summary'])
            if total_gaps > 0:
                f.write("## Implementation Gaps\n\n")

                for priority in [GapPriority.CRITICAL.value, GapPriority.HIGH.value,
                               GapPriority.MEDIUM.value, GapPriority.LOW.value]:
                    gaps = stats['gaps_summary'][priority]
                    if gaps:
                        icon = {"critical": "🔴", "high": "🟠", "medium": "🟡", "low": "🟢"}
                        f.write(f"### {icon[priority]} {priority.title()} Priority ({len(gaps)} gaps)\n\n")

                        for gap in gaps:
                            f.write(f"- `{gap['endpoint']}` - {gap['status']}\n")
                            if gap['notes']:
                                f.write(f"  - {gap['notes']}\n")

                        f.write("\n")

            # Legend
            f.write("## Legend\n\n")
            f.write("- ✅ **Fully Supported**: Complete implementation with all features\n")
            f.write("- ⚠️ **Partially Supported**: Basic functionality with some limitations\n")
            f.write("- ❌ **Not Supported**: Endpoint not implemented\n")
            f.write("- 🔄 **Deprecated**: Deprecated endpoint with alternative available\n")

        print(f"✓ Markdown report written to {output_path}")

    def generate_comparison_report(self, output_path: str) -> None:
        """Generate detailed comparison JSON report"""
        print(f"\nGenerating comparison report: {output_path}")

        stats = self.calculate_statistics()
        gaps = self.generate_gaps_analysis()

        report = {
            'metadata': {
                'horizon_version': self.horizon_version,
                'horizon_release_date': self.horizon_release_date,
                'horizon_release_url': self.horizon_release_url,
                'horizon_endpoints': self.horizon_data['metadata']['total_endpoints'],
                'sdk_request_builders': self.sdk_data['metadata']['total_request_builders'],
                'comparison_date': datetime.now().isoformat(),
                'horizon_source': self.horizon_data['metadata']['source'],
                'sdk_version': self.sdk_data['metadata']['sdk_version'],
                'coverage_percentage': stats['overall']['coverage_percentage']
            },
            'endpoint_comparison': [
                {
                    'category': comp.category,
                    'horizon_endpoint': comp.horizon_endpoint,
                    'sdk_implementation': comp.sdk_implementation,
                    'status': comp.status,
                    'notes': comp.notes,
                    'missing_features': comp.missing_features,
                    'priority': comp.priority
                }
                for comp in self.comparisons
            ],
            'gaps': gaps
        }

        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)

        print(f"✓ Comparison report written to {output_path}")

    def generate_gaps_analysis(self) -> Dict[str, Any]:
        """Generate detailed gap analysis"""
        missing_endpoints = []
        partial_implementations = []
        missing_features = {}

        for comp in self.comparisons:
            if comp.status == CompatibilityStatus.NOT_SUPPORTED.value:
                missing_endpoints.append({
                    'path': comp.horizon_endpoint['path'],
                    'method': comp.horizon_endpoint['method'],
                    'category': comp.category,
                    'description': comp.horizon_endpoint.get('description', ''),
                    'priority': comp.priority
                })

            elif comp.status == CompatibilityStatus.PARTIALLY_SUPPORTED.value:
                partial_implementations.append({
                    'path': comp.horizon_endpoint['path'],
                    'method': comp.horizon_endpoint['method'],
                    'category': comp.category,
                    'sdk_method': comp.sdk_implementation.get('sdk_method', ''),
                    'missing_features': comp.missing_features,
                    'priority': comp.priority
                })

            if comp.missing_features:
                endpoint_key = f"{comp.horizon_endpoint['method']} {comp.horizon_endpoint['path']}"
                missing_features[endpoint_key] = comp.missing_features

        return {
            'missing_endpoints': missing_endpoints,
            'partial_implementations': partial_implementations,
            'missing_features': missing_features
        }

    def generate_statistics_report(self, output_path: str) -> None:
        """Generate statistics JSON report"""
        print(f"\nGenerating statistics report: {output_path}")

        stats = self.calculate_statistics()

        report = {
            'generated_at': datetime.now().isoformat(),
            'horizon_version': self.horizon_version,
            'horizon_release_date': self.horizon_release_date,
            'horizon_release_url': self.horizon_release_url,
            'horizon_commit': self.horizon_data['metadata'].get('commit', 'unknown'),
            'sdk_version': self.sdk_data['metadata']['sdk_version'],
            'overall': stats['overall'],
            'by_category': stats['by_category'],
            'streaming': stats['streaming'],
            'gaps_summary': stats['gaps_summary']
        }

        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)

        print(f"✓ Statistics report written to {output_path}")

    def print_summary(self) -> None:
        """Print a summary of the comparison results to console"""
        stats = self.calculate_statistics()

        print("\n" + "=" * 70)
        print("HORIZON API vs FLUTTER SDK COMPATIBILITY SUMMARY")
        print("=" * 70)

        # Display Horizon version information
        horizon_version_display = self.horizon_version
        if self.horizon_release_date != "Unknown":
            horizon_version_display += f" (released {self.horizon_release_date})"
        print(f"\nHorizon Version: {horizon_version_display}")
        if self.horizon_release_url:
            print(f"Horizon Source:  {self.horizon_release_url}")
        print(f"SDK Version:     {self.sdk_data['metadata']['sdk_version']}")

        overall = stats['overall']
        print(f"\nOverall Coverage: {overall['coverage_percentage']}%")
        print(f"  ✅ Fully Supported:     {overall['fully_supported']}/{overall['total_endpoints']}")
        print(f"  ⚠️  Partially Supported: {overall['partially_supported']}/{overall['total_endpoints']}")
        print(f"  ❌ Not Supported:       {overall['not_supported']}/{overall['total_endpoints']}")
        print(f"  🔄 Deprecated:          {overall['deprecated']}/{overall['total_endpoints']}")

        print("\nCategory Breakdown:")
        for category, cat_stats in sorted(stats['by_category'].items()):
            print(f"  {category:20s}: {cat_stats['percentage']:5.1f}% "
                  f"({cat_stats['supported']}/{cat_stats['total']})")

        streaming = stats['streaming']
        print(f"\nStreaming Support: {streaming['percentage']:.1f}% "
              f"({streaming['supported']}/{streaming['total_streaming_endpoints']})")

        print("\nImplementation Gaps by Priority:")
        gaps = stats['gaps_summary']
        for priority in [GapPriority.CRITICAL.value, GapPriority.HIGH.value,
                        GapPriority.MEDIUM.value, GapPriority.LOW.value]:
            count = len(gaps[priority])
            if count > 0:
                icon = {"critical": "🔴", "high": "🟠", "medium": "🟡", "low": "🟢"}
                print(f"  {icon[priority]} {priority.upper():10s}: {count} gaps")

        print("\n" + "=" * 70)


def main():
    """Main entry point for the script"""
    print("Horizon API vs Flutter SDK Compatibility Analysis")
    print("=" * 70)

    # Define paths
    compatibility_dir = Path(__file__).parent.parent.parent.parent / 'compatibility'
    data_dir = Path(__file__).parent.parent / 'data' / 'horizon'

    horizon_data_path = data_dir / 'horizon_endpoints.json'
    sdk_data_path = data_dir / 'flutter_sdk_implementation.json'
    comparison_output_path = data_dir / 'compatibility_comparison.json'
    statistics_output_path = data_dir / 'coverage_stats.json'
    markdown_output_path = compatibility_dir / 'horizon' / 'HORIZON_COMPATIBILITY_MATRIX.md'

    # Verify input files exist
    if not horizon_data_path.exists():
        print(f"ERROR: Horizon endpoints file not found: {horizon_data_path}")
        print("Please run horizon_parser.py first.")
        return 1

    if not sdk_data_path.exists():
        print(f"ERROR: SDK implementation file not found: {sdk_data_path}")
        print("Please run sdk_analyzer.py first.")
        return 1

    # Create comparator
    comparator = HorizonSDKComparator(
        str(horizon_data_path),
        str(sdk_data_path)
    )

    try:
        # Load data
        comparator.load_data()

        # Compare endpoints
        comparator.compare_endpoints()

        # Generate reports
        comparator.generate_comparison_report(str(comparison_output_path))
        comparator.generate_statistics_report(str(statistics_output_path))
        comparator.generate_markdown_report(str(markdown_output_path))

        # Print summary
        comparator.print_summary()

        print("\n✓ Comparison complete!")
        print(f"\nOutput files:")
        print(f"  - Comparison: {comparison_output_path}")
        print(f"  - Statistics: {statistics_output_path}")
        print(f"  - Markdown:   {markdown_output_path}")

        return 0

    except Exception as e:
        print(f"\n❌ ERROR: {str(e)}")
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
