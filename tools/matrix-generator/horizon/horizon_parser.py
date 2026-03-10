#!/usr/bin/env python3
"""
Horizon API Endpoint Parser

Parses the Horizon Go router.go file to extract all HTTP endpoints with their
methods, parameters, and streaming capabilities. Outputs structured JSON data
for compatibility analysis.

This parser handles chi router's nested Route() blocks and complex routing patterns.

Author: Stellar Flutter SDK Team
License: Apache-2.0
"""

import argparse
import json
import re
import sys
import traceback
from datetime import datetime
from pathlib import Path

# Add parent dir to path for shared modules
sys.path.insert(0, str(Path(__file__).parent.parent))
from typing import Dict, List, Set, Tuple, Optional


class HorizonEndpoint:
    """Represents a single Horizon API endpoint"""

    def __init__(self, path: str, method: str, category: str, streaming: bool,
                 parameters: List[Dict[str, str]], description: str = "", handler: str = ""):
        self.path = path
        self.method = method
        self.category = category
        self.streaming = streaming
        self.parameters = parameters
        self.description = description
        self.handler = handler

    def to_dict(self) -> Dict:
        """Convert to dictionary for JSON serialization"""
        return {
            "path": self.path,
            "method": self.method,
            "category": self.category,
            "streaming": self.streaming,
            "parameters": self.parameters,
            "description": self.description,
            "handler": self.handler
        }


class HorizonRouterParser:
    """Parser for Horizon router.go file with nested Route() support"""

    # Known query parameters for various endpoints
    QUERY_PARAMETERS = {
        "cursor": {"description": "A number that points to a specific location in a collection of responses"},
        "limit": {"description": "The maximum number of records returned"},
        "order": {"description": "The order in which to return rows, 'asc' or 'desc'"},
        "asset": {"description": "Filter by asset"},
        "asset_code": {"description": "The code for the asset"},
        "asset_issuer": {"description": "The Stellar address of the asset issuer"},
        "signer": {"description": "Filter accounts by signer account ID"},
        "sponsor": {"description": "Filter by sponsor account ID"},
        "liquidity_pool": {"description": "Filter by liquidity pool ID"},
        "reserves": {"description": "Filter by reserve assets"},
        "account": {"description": "Filter by account ID"},
        "claimant": {"description": "Filter by claimant account ID"},
        "type": {"description": "Filter by type"},
        "selling_asset_type": {"description": "The type of asset being sold"},
        "selling_asset_code": {"description": "The code of asset being sold"},
        "selling_asset_issuer": {"description": "The issuer of asset being sold"},
        "buying_asset_type": {"description": "The type of asset being bought"},
        "buying_asset_code": {"description": "The code of asset being bought"},
        "buying_asset_issuer": {"description": "The issuer of asset being bought"},
        "seller": {"description": "Filter by seller account ID"},
        "offer_id": {"description": "Filter by offer ID"},
        "base_asset_type": {"description": "The type of the base asset"},
        "base_asset_code": {"description": "The code of the base asset"},
        "base_asset_issuer": {"description": "The issuer of the base asset"},
        "counter_asset_type": {"description": "The type of the counter asset"},
        "counter_asset_code": {"description": "The code of the counter asset"},
        "counter_asset_issuer": {"description": "The issuer of the counter asset"},
        "start_time": {"description": "Start time for aggregation period"},
        "end_time": {"description": "End time for aggregation period"},
        "resolution": {"description": "Segment duration as millis since epoch"},
        "offset": {"description": "Offset in milliseconds"},
        "include_failed": {"description": "Include failed transactions"},
        "join": {"description": "Include related resources"},
        "tx": {"description": "Transaction envelope XDR"},
    }

    def __init__(self, router_path: Optional[str] = None, version_info: Optional[Dict] = None):
        """
        Initialize parser with path to router.go

        Args:
            router_path: Path to Horizon router.go file (optional if using parse_from_content)
            version_info: Optional version metadata dict with keys:
                - horizon_version: Version tag (e.g., "v2.30.0")
                - published_at: Release publication date
                - release_url: GitHub release URL
        """
        self.router_path = Path(router_path) if router_path else None
        self.version_info = version_info or {}
        self.endpoints: List[HorizonEndpoint] = []
        self.categories: Dict[str, List[HorizonEndpoint]] = {}
        self.seen_endpoints: Set[Tuple[str, str]] = set()  # Track (path, method) to avoid duplicates

    def parse(self) -> None:
        """Parse the router.go file and extract endpoints"""
        if not self.router_path:
            raise ValueError("router_path must be provided when using parse() method")

        print(f"Parsing Horizon router: {self.router_path}")

        if not self.router_path.exists():
            raise FileNotFoundError(f"Router file not found: {self.router_path}")

        content = self.router_path.read_text()

        # Extract route definitions from addRoutes method
        self._parse_add_routes_method(content)

        # Organize by category
        self._organize_by_category()

        print(f"Extracted {len(self.endpoints)} endpoints across {len(self.categories)} categories")

    def parse_from_content(self, content: str) -> None:
        """
        Parse router content from string instead of file

        Args:
            content: The router.go file content as string
        """
        print("Parsing Horizon router from content")

        # Extract route definitions from addRoutes method
        self._parse_add_routes_method(content)

        # Organize by category
        self._organize_by_category()

        print(f"Extracted {len(self.endpoints)} endpoints across {len(self.categories)} categories")

    def _parse_add_routes_method(self, content: str) -> None:
        """Parse the addRoutes method which contains all route definitions"""
        # Find the addRoutes method
        method_match = re.search(
            r'func \(r \*Router\) addRoutes\([^)]+\) \{(.+?)^}',
            content,
            re.MULTILINE | re.DOTALL
        )

        if not method_match:
            print("WARNING: Could not find addRoutes method")
            return

        method_body = method_match.group(1)
        lines = method_body.split('\n')

        # Parse with context tracking
        self._parse_routes_recursive(lines, "", 0, len(lines))

    def _parse_routes_recursive(self, lines: List[str], path_prefix: str, start: int, end: int) -> None:
        """
        Recursively parse route definitions, handling nested Route() blocks

        Args:
            lines: All lines from the method body
            path_prefix: Current path prefix from parent Route() blocks
            start: Start line index
            end: End line index
        """
        i = start
        while i < end:
            line = lines[i].strip()

            # Skip empty lines and comments
            if not line or line.startswith('//'):
                i += 1
                continue

            # Check for r.Route() - nested route block
            route_match = re.match(r'r\.Route\s*\(\s*"([^"]+)"\s*,\s*func\s*\(\s*r\s+chi\.Router\s*\)\s*\{', line)
            if route_match:
                nested_path = route_match.group(1)
                # Find matching closing brace
                brace_count = 1
                block_start = i + 1
                j = i + 1
                while j < end and brace_count > 0:
                    if '{' in lines[j]:
                        brace_count += lines[j].count('{')
                    if '}' in lines[j]:
                        brace_count -= lines[j].count('}')
                    j += 1
                block_end = j - 1

                # Recursively parse nested block with updated path prefix
                new_prefix = path_prefix + nested_path
                self._parse_routes_recursive(lines, new_prefix, block_start, block_end)
                i = j
                continue

            # Check for r.Group() - route group without path prefix
            group_match = re.match(r'r\.Group\s*\(\s*func\s*\(\s*r\s+chi\.Router\s*\)\s*\{', line)
            if group_match:
                # Find matching closing brace
                brace_count = 1
                block_start = i + 1
                j = i + 1
                while j < end and brace_count > 0:
                    if '{' in lines[j]:
                        brace_count += lines[j].count('{')
                    if '}' in lines[j]:
                        brace_count -= lines[j].count('}')
                    j += 1
                block_end = j - 1

                # Recursively parse group block with same path prefix
                self._parse_routes_recursive(lines, path_prefix, block_start, block_end)
                i = j
                continue

            # Check for multi-line Method() calls - look ahead to construct full line
            # Pattern: r.With(...).Method(
            #              http.MethodGet,
            #              "/path",
            #              handler
            #          )
            if 'r.With(' in line and '.Method(' in line and 'http.Method' not in line:
                # This is likely a multi-line Method() call, combine lines
                combined_line = line
                j = i + 1
                paren_count = line.count('(') - line.count(')')
                while j < end and paren_count > 0:
                    next_line = lines[j].strip()
                    combined_line += ' ' + next_line
                    paren_count += next_line.count('(') - next_line.count(')')
                    j += 1
                line = combined_line
                i = j - 1  # Will be incremented at end of loop

            # Check for route definition with .With() middleware
            # Pattern: r.With(...).Method(http.MethodGet, "/path", handler)
            with_method_match = re.search(
                r'r\.With\([^)]+\)\.Method\s*\(\s*http\.Method(\w+)\s*,\s*"([^"]+)"\s*,',
                line
            )
            if with_method_match:
                method = with_method_match.group(1).upper()
                path = path_prefix + with_method_match.group(2)
                self._add_endpoint(path, method, line)
                i += 1
                continue

            # Check for simple .Method() calls
            # Pattern: r.Method(http.MethodGet, "/path", handler)
            method_match = re.search(
                r'r\.Method\s*\(\s*http\.Method(\w+)\s*,\s*"([^"]+)"\s*,',
                line
            )
            if method_match:
                method = method_match.group(1).upper()
                path = path_prefix + method_match.group(2)
                self._add_endpoint(path, method, line)
                i += 1
                continue

            # Check for shorthand methods: r.Get(), r.Post(), etc.
            shorthand_match = re.search(
                r'r\.(Get|Post|Put|Delete|Patch)\s*\(\s*"([^"]+)"\s*,',
                line
            )
            if shorthand_match:
                method = shorthand_match.group(1).upper()
                path = path_prefix + shorthand_match.group(2)
                self._add_endpoint(path, method, line)
                i += 1
                continue

            i += 1

    def _add_endpoint(self, path: str, method: str, line: str) -> None:
        """Add an endpoint to the list"""
        # Skip internal endpoints
        if path.startswith("/debug") or path.startswith("/metrics") or "/internal/" in path:
            return

        # Normalize path parameters
        path = self._normalize_path(path)

        # Check for duplicates
        endpoint_key = (path, method)
        if endpoint_key in self.seen_endpoints:
            return
        self.seen_endpoints.add(endpoint_key)

        # Determine category from path
        category = self._determine_category(path)

        # Check if streaming is supported
        streaming = self._is_streaming(path, line)

        # Extract parameters
        parameters = self._extract_parameters(path, category, method)

        # Extract handler name if available
        handler = self._extract_handler(line)

        # Create endpoint
        endpoint = HorizonEndpoint(
            path=path,
            method=method,
            category=category,
            streaming=streaming,
            parameters=parameters,
            description=self._generate_description(path, category, method),
            handler=handler
        )

        self.endpoints.append(endpoint)

    def _normalize_path(self, path: str) -> str:
        """Normalize path parameters to consistent format"""
        # Remove regex patterns from parameters (e.g., {account_id:\\w+} -> {account_id})
        normalized = re.sub(r'\{([^:}]+):[^}]+\}', r'{\1}', path)

        # Remove trailing slashes (except for root path)
        if normalized != '/' and normalized.endswith('/'):
            normalized = normalized.rstrip('/')

        # Normalize generic parameter names to specific ones
        replacements = {
            r'/accounts/\{id\}': '/accounts/{account_id}',
            r'/ledgers/\{id\}': '/ledgers/{ledger_id}',
            r'/transactions/\{id\}': '/transactions/{transaction_id}',
            r'/operations/\{id\}': '/operations/{operation_id}',
            r'/claimable_balances/\{id\}': '/claimable_balances/{claimable_balance_id}',
            r'/liquidity_pools/\{id\}': '/liquidity_pools/{liquidity_pool_id}',
            r'/offers/\{id\}': '/offers/{offer_id}',
            r'/effects/\{id\}': '/effects/{effect_id}',
        }

        for pattern, replacement in replacements.items():
            if re.search(pattern, normalized):
                normalized = re.sub(pattern, replacement, normalized)

        # Handle other parameter name variations
        normalized = normalized.replace('{tx_id}', '{transaction_id}')
        normalized = normalized.replace('{op_id}', '{operation_id}')
        normalized = normalized.replace('{sequence}', '{ledger_sequence}')

        return normalized

    def _determine_category(self, path: str) -> str:
        """Determine endpoint category from path"""
        # Extract the first path segment after /
        parts = path.strip('/').split('/')
        if parts:
            return parts[0]
        return "other"

    def _is_streaming(self, path: str, line: str) -> bool:
        """Check if endpoint supports streaming by looking for streamHandler"""
        # Check if line contains streaming-related handlers
        if 'streamHandler' in line or 'StreamHandler' in line:
            return True

        # Check if line contains streamable* wrappers
        if 'streamable' in line.lower():
            return True

        # Special handling: All collection/list endpoints that use streamableObjectActionHandler
        # or streamableHistoryPageHandler or streamableStatePageHandler support streaming
        # However, those using restPageHandler do NOT support streaming per the code
        # The streaming is determined by the handler type, which we check above

        return False

    def _extract_parameters(self, path: str, category: str, method: str = "GET") -> List[Dict[str, str]]:
        """Extract parameters from path and add common query parameters"""
        parameters = []

        # Extract path parameters
        path_params = re.findall(r'\{([^}]+)\}', path)
        for param in path_params:
            param_name = param.replace('_', ' ')
            parameters.append({
                "name": param,
                "location": "path",
                "required": "true",
                "description": f"The {param_name}"
            })

        # POST endpoints have different parameters than GET endpoints
        # For POST /transactions and /transactions_async, only add 'tx' parameter
        if method == "POST" and (path == '/transactions' or path == '/transactions_async'):
            parameters.append({
                "name": "tx",
                "location": "body",
                "required": "true",
                "description": self.QUERY_PARAMETERS["tx"]["description"]
            })
            return parameters

        # Add common query parameters for list endpoints (GET only)
        # List endpoints are those without parameters or with a parent resource followed by a list
        is_list_endpoint = (
            '/{' not in path or  # No parameters (e.g., /accounts)
            (path.count('/') > 2 and not path.endswith('}'))  # Resource list (e.g., /accounts/{id}/operations)
        )

        if is_list_endpoint:
            # Pagination parameters for all list endpoints
            for param in ['cursor', 'limit', 'order']:
                if param in self.QUERY_PARAMETERS:
                    parameters.append({
                        "name": param,
                        "location": "query",
                        "required": "false",
                        "description": self.QUERY_PARAMETERS[param]["description"]
                    })

        # Add endpoint-specific query parameters
        if category == 'accounts' and path == '/accounts':
            for param in ['asset', 'signer', 'sponsor', 'liquidity_pool']:
                if param in self.QUERY_PARAMETERS:
                    parameters.append({
                        "name": param,
                        "location": "query",
                        "required": "false",
                        "description": self.QUERY_PARAMETERS[param]["description"]
                    })
        elif category == 'assets':
            for param in ['asset_code', 'asset_issuer']:
                if param in self.QUERY_PARAMETERS:
                    parameters.append({
                        "name": param,
                        "location": "query",
                        "required": "false",
                        "description": self.QUERY_PARAMETERS[param]["description"]
                    })
        elif category == 'claimable_balances' and path == '/claimable_balances':
            for param in ['asset', 'sponsor', 'claimant']:
                if param in self.QUERY_PARAMETERS:
                    parameters.append({
                        "name": param,
                        "location": "query",
                        "required": "false",
                        "description": self.QUERY_PARAMETERS[param]["description"]
                    })
        elif category == 'liquidity_pools' and path == '/liquidity_pools':
            for param in ['reserves', 'account']:
                if param in self.QUERY_PARAMETERS:
                    parameters.append({
                        "name": param,
                        "location": "query",
                        "required": "false",
                        "description": self.QUERY_PARAMETERS[param]["description"]
                    })
        elif category == 'offers':
            if path == '/offers':
                for param in ['seller', 'selling_asset_type', 'selling_asset_code',
                             'selling_asset_issuer', 'buying_asset_type', 'buying_asset_code',
                             'buying_asset_issuer', 'sponsor']:
                    if param in self.QUERY_PARAMETERS:
                        parameters.append({
                            "name": param,
                            "location": "query",
                            "required": "false",
                            "description": self.QUERY_PARAMETERS[param]["description"]
                        })
        elif category == 'trades' or 'trades' in path:
            for param in ['base_asset_type', 'base_asset_code', 'base_asset_issuer',
                         'counter_asset_type', 'counter_asset_code', 'counter_asset_issuer',
                         'offer_id', 'account', 'type']:
                if param in self.QUERY_PARAMETERS:
                    parameters.append({
                        "name": param,
                        "location": "query",
                        "required": "false",
                        "description": self.QUERY_PARAMETERS[param]["description"]
                    })
        elif 'trade_aggregations' in path:
            for param in ['start_time', 'end_time', 'resolution', 'offset',
                         'base_asset_type', 'base_asset_code', 'base_asset_issuer',
                         'counter_asset_type', 'counter_asset_code', 'counter_asset_issuer']:
                if param in self.QUERY_PARAMETERS:
                    parameters.append({
                        "name": param,
                        "location": "query",
                        "required": "false",
                        "description": self.QUERY_PARAMETERS[param]["description"]
                    })
        elif category == 'transactions':
            # Only add include_failed to GET endpoints (list endpoints)
            if method == "GET" and (path == '/transactions' or path.endswith('/transactions')):
                parameters.append({
                    "name": "include_failed",
                    "location": "query",
                    "required": "false",
                    "description": self.QUERY_PARAMETERS["include_failed"]["description"]
                })

        return parameters

    def _extract_handler(self, line: str) -> str:
        """Extract handler name from route definition line"""
        # Look for handler names - typically after the path
        # Pattern: actions.HandlerName{...} or just HandlerName
        handler_match = re.search(r'actions\.(\w+)', line)
        if handler_match:
            return handler_match.group(1)

        # Look for other handler patterns
        handler_patterns = [
            r'ObjectActionHandler\{.*?(\w+Handler)',
            r'streamable\w+\([^,]+,\s*actions\.(\w+)',
        ]

        for pattern in handler_patterns:
            match = re.search(pattern, line)
            if match:
                return match.group(1)

        return ""

    def _generate_description(self, path: str, category: str, method: str) -> str:
        """Generate endpoint description"""
        # Special cases
        if path == '/fee_stats':
            return "Retrieve current fee statistics"
        if path == '/order_book':
            return "Retrieve the orderbook for a trading pair"
        if 'paths' in path:
            if 'strict-send' in path:
                return "Find payment paths for strict send"
            elif 'strict-receive' in path:
                return "Find payment paths for strict receive"
            return "Find payment paths between assets"
        if 'trade_aggregations' in path:
            return "Retrieve trade aggregations"

        # Check if it's a submission endpoint
        if method == 'POST' and category == 'transactions':
            if 'async' in path:
                return "Submit a transaction asynchronously"
            return "Submit a transaction to the network"

        # Check if it's a detail endpoint (single resource)
        has_param = '/{' in path
        is_detail = has_param and path.endswith('}')

        # Category-specific descriptions
        category_actions = {
            "accounts": "account",
            "assets": "asset",
            "claimable_balances": "claimable balance",
            "effects": "effect",
            "ledgers": "ledger",
            "liquidity_pools": "liquidity pool",
            "offers": "offer",
            "operations": "operation",
            "payments": "payment",
            "trades": "trade",
            "transactions": "transaction",
        }

        resource_name = category_actions.get(category, category.replace('_', ' '))

        if is_detail:
            return f"Retrieve a single {resource_name}"
        elif has_param:
            # This is a sub-resource list (e.g., /accounts/{id}/operations)
            sub_resource = path.split('/')[-1]
            sub_resource_name = category_actions.get(sub_resource, sub_resource.replace('_', ' '))
            return f"Retrieve {sub_resource_name}s for a {resource_name}"
        else:
            # This is a top-level list
            return f"List all {resource_name}s"

    def _organize_by_category(self) -> None:
        """Organize endpoints by category"""
        for endpoint in self.endpoints:
            if endpoint.category not in self.categories:
                self.categories[endpoint.category] = []
            self.categories[endpoint.category].append(endpoint)

    def to_json(self) -> Dict:
        """Convert parsed data to JSON structure"""
        metadata = {
            "source": str(self.router_path) if self.router_path else "GitHub",
            "generated_at": datetime.now().isoformat(),
            "total_endpoints": len(self.endpoints),
            "total_categories": len(self.categories)
        }

        # Add version information if available
        if self.version_info:
            if "horizon_version" in self.version_info:
                metadata["horizon_version"] = self.version_info["horizon_version"]
            if "published_at" in self.version_info:
                metadata["horizon_release_date"] = self.version_info["published_at"]
            if "release_url" in self.version_info:
                metadata["horizon_release_url"] = self.version_info["release_url"]

        return {
            "metadata": metadata,
            "categories": {
                category: {
                    "total": len(endpoints),
                    "endpoints": [ep.to_dict() for ep in endpoints]
                }
                for category, endpoints in sorted(self.categories.items())
            },
            "endpoints": [ep.to_dict() for ep in self.endpoints]
        }

    def save_json(self, output_path: str) -> None:
        """Save parsed data to JSON file"""
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)

        data = self.to_json()

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

        print(f"Saved endpoint data to: {output_path}")


def parse_from_local(router_path: Path, output_path: Path) -> int:
    """
    Parse from local file (backwards compatibility mode)

    Args:
        router_path: Path to local router.go file
        output_path: Path to output JSON file

    Returns:
        Exit code (0 for success, 1 for failure)
    """
    # Verify input file exists
    if not router_path.exists():
        print(f"ERROR: Router file not found: {router_path}")
        print("Please ensure stellar-go repository is cloned locally.")
        return 1

    try:
        # Parse router
        parser = HorizonRouterParser(str(router_path))
        parser.parse()

        # Save results
        parser.save_json(str(output_path))

        # Print summary
        print()
        print("=" * 70)
        print("SUMMARY")
        print("=" * 70)
        print(f"Total Endpoints: {len(parser.endpoints)}")
        print(f"Total Categories: {len(parser.categories)}")
        print()
        print("Endpoints by Category:")
        for category, endpoints in sorted(parser.categories.items()):
            print(f"  {category:25s}: {len(endpoints):3d} endpoints")
        print()
        print("=" * 70)
        print("Parsing completed successfully!")
        print("=" * 70)

        return 0

    except Exception as e:
        print(f"\nERROR: {str(e)}")
        traceback.print_exc()
        return 1


def main():
    """Main entry point"""
    from common import SDK_ROOT

    parser = argparse.ArgumentParser(
        description="Parse Horizon API endpoints from router.go",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Parse from local file (default, expects stellar-go as sibling of SDK)
  %(prog)s

  # Parse local file with custom paths
  %(prog)s --local /path/to/router.go --output /path/to/output.json
        """
    )

    parser.add_argument(
        '--local',
        type=str,
        help='Path to local router.go file (default: ../stellar-go relative to SDK root)'
    )

    parser.add_argument(
        '--output',
        type=str,
        help='Path to output JSON file'
    )

    args = parser.parse_args()

    print("=" * 70)
    print("Horizon API Endpoint Parser")
    print("=" * 70)
    print()

    # Determine output path
    if args.output:
        output_path = Path(args.output)
    else:
        output_path = Path(__file__).parent.parent / "data" / "horizon" / "horizon_endpoints.json"

    print("Mode: Local file")
    print()

    # Determine router path
    if args.local:
        router_path = Path(args.local)
    else:
        router_path = SDK_ROOT.parent / "stellar-go" / "services" / "horizon" / "internal" / "httpx" / "router.go"

    return parse_from_local(router_path, output_path)


if __name__ == '__main__':
    sys.exit(main())
