#!/usr/bin/env python3
"""
Flutter SDK Implementation Analyzer

Analyzes Flutter SDK request builders and exposed methods to extract implementation
details including supported endpoints, parameters, filters, and streaming capabilities.

Uses dynamic code analysis to detect endpoints and filter parameters from source code,
reducing maintenance burden when builders are added or modified.

Author: Stellar Flutter SDK Team
License: Apache-2.0
"""

import json
import re
import sys
import traceback
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum

from common import get_sdk_version


class DetectionSource(Enum):
    """Source of detection for endpoints and parameters"""
    DYNAMIC = "dynamic"  # Detected from code analysis
    FALLBACK = "fallback"  # From hardcoded fallback mapping
    HYBRID = "hybrid"  # Combination of both


@dataclass
class RequestBuilderInfo:
    """Information about a request builder class"""
    class_name: str
    file_path: str
    endpoints: List[str]
    methods: List[Dict[str, str]]
    filter_methods: List[Dict[str, str]]
    streaming_support: bool
    exposed_in_sdk: bool
    sdk_property: str = ""
    endpoint_detection_source: str = DetectionSource.DYNAMIC.value
    filter_detection_confidence: float = 1.0

    def to_dict(self) -> Dict:
        """Convert to dictionary for JSON serialization"""
        return {
            "class_name": self.class_name,
            "file_path": self.file_path,
            "endpoints": self.endpoints,
            "methods": self.methods,
            "filter_methods": self.filter_methods,
            "streaming_support": self.streaming_support,
            "exposed_in_sdk": self.exposed_in_sdk,
            "sdk_property": self.sdk_property,
            "endpoint_detection_source": self.endpoint_detection_source,
            "filter_detection_confidence": self.filter_detection_confidence
        }


class FlutterSDKAnalyzer:
    """Analyzer for Flutter SDK implementation"""

    # Fallback endpoint mappings for edge cases where dynamic detection may fail
    # These serve as overrides or supplements to dynamic detection
    BUILDER_ENDPOINTS_FALLBACK = {
        "AccountsRequestBuilder": ["/accounts", "/accounts/{account_id}", "/accounts/{account_id}/data/{key}"],
        "AssetsRequestBuilder": ["/assets"],
        "ClaimableBalancesRequestBuilder": ["/claimable_balances", "/claimable_balances/{claimable_balance_id}"],
        "EffectsRequestBuilder": ["/effects"],
        "FeeStatsRequestBuilder": ["/fee_stats"],
        "HealthRequestBuilder": ["/health"],
        "LedgersRequestBuilder": ["/ledgers", "/ledgers/{ledger_sequence}"],
        "LiquidityPoolsRequestBuilder": ["/liquidity_pools", "/liquidity_pools/{liquidity_pool_id}"],
        "LiquidityPoolTradesRequestBuilder": [],
        "OffersRequestBuilder": ["/offers", "/offers/{offer_id}", "/offers/{offer_id}/trades"],
        "OperationsRequestBuilder": ["/operations", "/operations/{operation_id}"],
        "OrderBookRequestBuilder": ["/order_book"],
        "PaymentsRequestBuilder": ["/payments"],
        "StrictSendPathsRequestBuilder": ["/paths/strict-send"],
        "StrictReceivePathsRequestBuilder": ["/paths/strict-receive"],
        "TradeAggregationsRequestBuilder": ["/trade_aggregations"],
        "TradesRequestBuilder": ["/trades", "/accounts/{account_id}/trades", "/liquidity_pools/{liquidity_pool_id}/trades"],
        "TransactionsRequestBuilder": ["/transactions", "/transactions/{transaction_id}"],
    }

    # Path parameter name normalization (Dart camelCase -> Horizon snake_case)
    PATH_PARAMETER_NORMALIZATION = {
        "accountId": "account_id",
        "ledgerSeq": "ledger_sequence",
        "ledgerId": "ledger_id",
        "transactionId": "transaction_id",
        "operationId": "operation_id",
        "offerId": "offer_id",
        "poolId": "liquidity_pool_id",
        "id": "id",  # Generic ID - will be context-normalized later
        "key": "key",
        "claimableBalanceId": "claimable_balance_id",
        "liquidityPoolId": "liquidity_pool_id",
    }

    # Fallback filter parameter mappings for complex cases
    FILTER_PARAMETER_FALLBACK = {
        "forAccount": "account_id",
        "forAsset": "asset",
        "forSigner": "signer",
        "forSponsor": "sponsor",
        "forLiquidityPool": "liquidity_pool",
        "forClaimant": "claimant",
        "forSeller": "seller",
        "forBuyingAsset": "buying_asset",
        "forSellingAsset": "selling_asset",
        "forOffer": "offer_id",
        "forTransaction": "transaction_id",
        "forLedger": "ledger_sequence",
        "forType": "type",
        "forReserveAssets": "reserves",
        "forPoolId": "liquidity_pool_id",
        "forClaimableBalance": "claimable_balance_id",
        "forOperation": "operation_id",
        "includeFailed": "include_failed",
        "join": "join",
        "assetCode": "asset_code",
        "assetIssuer": "asset_issuer",
        "baseAsset": "base_asset",
        "counterAsset": "counter_asset",
        "tradeType": "type",
        "offerId": "offer_id",
        "liquidityPoolId": "liquidity_pool_id",
        "sellingAsset": "selling_asset",
        "buyingAsset": "buying_asset",
        "sourceAccount": "source_account",
        "sourceAssets": "source_assets",
        "sourceAsset": "source_asset",
        "sourceAmount": "source_amount",
        "destinationAccount": "destination_account",
        "destinationAssets": "destination_assets",
        "destinationAsset": "destination_asset",
        "destinationAmount": "destination_amount",
    }

    def __init__(self, sdk_root: str):
        """
        Initialize analyzer with SDK root path

        Args:
            sdk_root: Path to Flutter SDK root directory
        """
        self.sdk_root = Path(sdk_root)
        self.requests_dir = self.sdk_root / "lib" / "src" / "requests"
        self.sdk_main = self.sdk_root / "lib" / "src" / "stellar_sdk.dart"
        self.builders: List[RequestBuilderInfo] = []
        self.exposed_builders: Set[str] = set()
        self.builder_properties: Dict[str, str] = {}
        self.sdk_methods: Dict[str, Dict] = {}
        self.direct_endpoints: Dict[str, Dict] = {}
        self.detection_stats = {
            "endpoints_dynamic": 0,
            "endpoints_fallback": 0,
            "filters_dynamic": 0,
            "filters_fallback": 0,
            "filters_hybrid": 0
        }

    def _normalize_path_parameter(self, param_name: str, endpoint_context: str = "") -> str:
        """
        Normalize a Dart path parameter name to Horizon's format.

        Args:
            param_name: The Dart variable name (e.g., 'accountId')
            endpoint_context: The endpoint path for context-aware normalization

        Returns:
            Normalized parameter name (e.g., 'account_id')
        """
        # First check direct mapping
        if param_name in self.PATH_PARAMETER_NORMALIZATION:
            normalized = self.PATH_PARAMETER_NORMALIZATION[param_name]

            # Handle generic 'id' based on context
            if normalized == "id" and endpoint_context:
                if "/claimable_balances" in endpoint_context:
                    return "claimable_balance_id"
                elif "/liquidity_pools" in endpoint_context:
                    return "liquidity_pool_id"
                elif "/offers" in endpoint_context:
                    return "offer_id"
                elif "/operations" in endpoint_context:
                    return "operation_id"
                elif "/transactions" in endpoint_context:
                    return "transaction_id"
                elif "/ledgers" in endpoint_context:
                    return "ledger_id"
                elif "/accounts" in endpoint_context:
                    return "account_id"
            return normalized

        # If not in mapping, convert camelCase to snake_case
        result = ""
        for i, char in enumerate(param_name):
            if char.isupper() and i > 0:
                result += "_" + char.lower()
            else:
                result += char.lower()
        return result

    def _normalize_endpoint(self, endpoint: str) -> str:
        """
        Normalize an endpoint path to match Horizon's format.

        Args:
            endpoint: Raw endpoint with Dart-style parameter names

        Returns:
            Normalized endpoint with Horizon-style parameter names
        """
        # Find all parameters in the endpoint
        param_pattern = r'\{([^}]+)\}'

        def replace_param(match):
            param = match.group(1)
            # Skip 'toString' which is a Dart method call artifact
            if param == "toString":
                return ""
            normalized = self._normalize_path_parameter(param, endpoint)
            return "{" + normalized + "}"

        normalized = re.sub(param_pattern, replace_param, endpoint)
        # Clean up any double slashes or trailing empties
        normalized = re.sub(r'/+', '/', normalized)
        normalized = normalized.rstrip('/')
        return normalized

    def analyze(self) -> None:
        """Perform complete analysis of SDK implementation"""
        print(f"Analyzing Flutter SDK: {self.sdk_root}")

        # First, find exposed builders in StellarSDK class
        self._analyze_sdk_class()

        # Analyze utility classes (like FriendBot)
        self._analyze_utility_classes()

        # Then analyze each request builder
        self._analyze_request_builders()

        # Build SDK methods mapping for comparison
        self._build_sdk_methods_mapping()

        print(f"Analyzed {len(self.builders)} request builders")
        print(f"Found {len(self.exposed_builders)} exposed in StellarSDK class")
        print(f"Found {len(self.direct_endpoints)} direct endpoint implementations")
        print("\nDetection statistics:")
        print(f"  Endpoints (dynamic): {self.detection_stats['endpoints_dynamic']}")
        print(f"  Endpoints (fallback): {self.detection_stats['endpoints_fallback']}")
        print(f"  Filters (dynamic): {self.detection_stats['filters_dynamic']}")
        print(f"  Filters (fallback): {self.detection_stats['filters_fallback']}")
        print(f"  Filters (hybrid): {self.detection_stats['filters_hybrid']}")

    def _analyze_sdk_class(self) -> None:
        """Analyze StellarSDK class to find exposed builders and direct endpoint implementations"""
        if not self.sdk_main.exists():
            print(f"WARNING: StellarSDK file not found: {self.sdk_main}")
            return

        content = self.sdk_main.read_text()

        # Find getter methods that return request builders
        # Pattern: BuilderType get property => BuilderType(...)
        getter_pattern = r'(\w+RequestBuilder)\s+get\s+(\w+)\s*=>'
        getter_matches = re.findall(getter_pattern, content)

        for builder_class, property_name in getter_matches:
            self.exposed_builders.add(builder_class)
            self.builder_properties[builder_class] = property_name

        # Find regular methods that return request builders
        # Pattern: BuilderType methodName(params)
        method_pattern = r'(\w+RequestBuilder)\s+(\w+)\s*\([^)]*\)\s*{'
        method_matches = re.findall(method_pattern, content)

        for builder_class, method_name in method_matches:
            self.exposed_builders.add(builder_class)
            self.builder_properties[builder_class] = method_name

        # Find direct endpoint implementations
        self._extract_direct_endpoints(content)

    def _extract_direct_endpoints(self, content: str) -> None:
        """Extract direct endpoint implementations from StellarSDK class"""
        # Special case: root() method uses _serverURI directly without pathSegments
        root_pattern = r'Future<RootResponse>\s+root\(\s*\)\s+async\s*\{[^}]*httpClient\.get\(_serverURI\)'
        if re.search(root_pattern, content, re.DOTALL):
            self.direct_endpoints["/"] = {
                "method": "root",
                "http_method": "GET",
                "return_type": "RootResponse",
                "implemented": True
            }
            print(f"  Found direct endpoint: GET / -> root()")

        # Find all methods that construct URIs with pathSegments
        # Pattern: _serverURI.replace(pathSegments: ["path"])
        path_pattern = r'_serverURI\.replace\(pathSegments:\s*\["([^"]+)"\]\)'

        # Find all URI constructions with their context
        for match in re.finditer(path_pattern, content):
            endpoint_path = "/" + match.group(1)

            # Find the method this URI is in by looking backwards from the match position
            method_start = content.rfind('Future<', 0, match.start())
            if method_start != -1:
                # Extract method signature
                method_end = content.find('(', method_start)
                method_line = content[method_start:method_end]

                # Extract return type and method name
                method_match = re.search(r'Future<(\w+)>\s+(\w+)$', method_line)
                if method_match:
                    return_type = method_match.group(1)
                    method_name = method_match.group(2)

                    # Determine HTTP method by looking at the code
                    method_body_start = match.start()
                    method_body_end = content.find('\n  }', match.end())
                    if method_body_end != -1:
                        method_body = content[method_body_start:method_body_end]

                        # Check if it uses POST
                        http_method = "POST" if '.post(' in method_body else "GET"

                        # Store the direct endpoint implementation
                        self.direct_endpoints[endpoint_path] = {
                            "method": method_name,
                            "http_method": http_method,
                            "return_type": return_type,
                            "implemented": True
                        }

                        print(f"  Found direct endpoint: {http_method} {endpoint_path} -> {method_name}()")

    def _analyze_utility_classes(self) -> None:
        """Analyze utility classes like FriendBot that provide direct endpoint access"""
        util_path = self.sdk_root / "lib" / "src" / "util.dart"
        if not util_path.exists():
            return

        content = util_path.read_text()

        # Check for FriendBot class with fundTestAccount method
        friendbot_pattern = r'class\s+FriendBot\s*\{[^}]*static\s+Future<bool>\s+fundTestAccount'
        if re.search(friendbot_pattern, content, re.DOTALL):
            self.direct_endpoints["/friendbot"] = {
                "method": "FriendBot.fundTestAccount",
                "http_method": "GET",
                "return_type": "bool",
                "implemented": True,
                "notes": "Testnet/Futurenet only"
            }
            print(f"  Found direct endpoint: GET /friendbot -> FriendBot.fundTestAccount()")

    def _analyze_request_builders(self) -> None:
        """Analyze all request builder files"""
        if not self.requests_dir.exists():
            raise FileNotFoundError(f"Requests directory not found: {self.requests_dir}")

        dart_files = list(self.requests_dir.glob("*_request_builder.dart"))
        print(f"Found {len(dart_files)} request builder files")

        for dart_file in sorted(dart_files):
            try:
                self._analyze_builder_file(dart_file)
            except Exception as e:
                print(f"WARNING: Error analyzing {dart_file.name}: {e}")

    def _analyze_builder_file(self, file_path: Path) -> None:
        """Analyze a single request builder file (may contain multiple classes)"""
        content = file_path.read_text()

        # Extract all class names - a file may contain multiple RequestBuilder classes
        class_matches = re.finditer(r'class\s+(\w+)\s+extends\s+RequestBuilder', content)

        found_classes = []
        for match in class_matches:
            class_name = match.group(1)
            found_classes.append(class_name)

        if not found_classes:
            return

        # Process each class found in the file
        for class_name in found_classes:
            # Extract class-specific content
            class_content = self._extract_class_content(content, class_name)

            # Dynamically determine endpoints
            endpoints, detection_source = self._extract_endpoints_dynamic(
                class_content, class_name
            )

            # Extract methods for this specific class
            methods = self._extract_methods(class_content, class_name)

            # Extract filter methods dynamically for this specific class
            filter_methods, confidence = self._extract_filter_methods_dynamic(
                class_content, class_name
            )

            # Check for streaming support
            streaming_support = 'Stream<' in class_content and 'stream()' in class_content

            # Check if exposed in SDK
            exposed_in_sdk = class_name in self.exposed_builders

            # Get SDK property/method name
            sdk_property = self.builder_properties.get(class_name, "")

            # Create builder info
            builder = RequestBuilderInfo(
                class_name=class_name,
                file_path=str(file_path.relative_to(self.sdk_root)),
                endpoints=endpoints,
                methods=methods,
                filter_methods=filter_methods,
                streaming_support=streaming_support,
                exposed_in_sdk=exposed_in_sdk,
                sdk_property=sdk_property,
                endpoint_detection_source=detection_source.value,
                filter_detection_confidence=confidence
            )

            self.builders.append(builder)

    def _extract_class_content(self, content: str, class_name: str) -> str:
        """Extract content for a specific class from file content"""
        class_pattern = rf'class\s+{re.escape(class_name)}\s+extends\s+RequestBuilder'
        class_match = re.search(class_pattern, content)

        if not class_match:
            return ""

        start_pos = class_match.start()

        # Find the next class definition or end of file
        next_class_pattern = r'class\s+\w+\s+extends\s+RequestBuilder'
        next_class_matches = list(re.finditer(
            next_class_pattern,
            content[start_pos + len(class_match.group(0)):]
        ))

        if next_class_matches:
            end_pos = start_pos + len(class_match.group(0)) + next_class_matches[0].start()
        else:
            end_pos = len(content)

        return content[start_pos:end_pos]

    def _extract_endpoints_dynamic(
        self,
        class_content: str,
        class_name: str
    ) -> Tuple[List[str], DetectionSource]:
        """
        Dynamically extract endpoints from request builder code

        Looks for:
        1. Constructor default segments: super(httpClient, serverURI, ["endpoint"])
        2. Methods with setSegments() calls
        3. buildUri() implementations with pathSegments

        Returns:
            Tuple of (endpoints list, detection source)
        """
        endpoints = []
        detection_source = DetectionSource.DYNAMIC

        # Pattern 1: Constructor with default segments
        # super(httpClient, serverURI, ["accounts"])
        constructor_pattern = r'super\s*\([^,]+,\s*[^,]+,\s*\[([^\]]+)\]\s*\)'
        constructor_match = re.search(constructor_pattern, class_content)

        if constructor_match:
            segments_str = constructor_match.group(1)
            # Extract quoted strings
            segments = re.findall(r'"([^"]+)"', segments_str)
            if segments:
                endpoint = "/" + "/".join(segments)
                endpoint = self._normalize_endpoint(endpoint)
                endpoints.append(endpoint)
                print(f"  [{class_name}] Detected endpoint from constructor: {endpoint}")

        # Pattern 2: Methods that call setSegments()
        # this.setSegments(["accounts", accountId, "trades"])
        set_segments_pattern = r'(?:this\.)?setSegments\s*\(\s*\[([^\]]+)\]\s*\)'
        for match in re.finditer(set_segments_pattern, class_content):
            segments_str = match.group(1)
            # Extract segments, handling both literals and variables
            segments = []
            for segment in re.findall(r'"([^"]+)"|(\w+)', segments_str):
                if segment[0]:  # Quoted string
                    segments.append(segment[0])
                elif segment[1]:  # Variable - use placeholder
                    segments.append("{" + segment[1] + "}")

            if segments:
                endpoint = "/" + "/".join(segments)
                endpoint = self._normalize_endpoint(endpoint)
                if endpoint and endpoint not in endpoints:
                    endpoints.append(endpoint)
                    print(f"  [{class_name}] Detected endpoint from setSegments: {endpoint}")

        # If dynamic detection found endpoints, mark as dynamic
        if endpoints:
            self.detection_stats["endpoints_dynamic"] += 1
        else:
            # Fall back to hardcoded mapping
            if class_name in self.BUILDER_ENDPOINTS_FALLBACK:
                endpoints = self.BUILDER_ENDPOINTS_FALLBACK[class_name]
                detection_source = DetectionSource.FALLBACK
                self.detection_stats["endpoints_fallback"] += 1
                print(f"  [{class_name}] Using fallback endpoints: {endpoints}")
            else:
                print(f"  WARNING: [{class_name}] No endpoints detected (dynamic or fallback)")

        return endpoints, detection_source

    def _extract_filter_methods_dynamic(
        self,
        class_content: str,
        class_name: str
    ) -> Tuple[List[Dict[str, str]], float]:
        """
        Dynamically extract filter methods and their parameter names

        Looks for methods that:
        1. Return the builder type (indicating method chaining)
        2. Set query parameters via queryParameters.addAll() or similar

        Returns:
            Tuple of (filter methods list, confidence score)
        """
        filter_methods = []
        dynamic_count = 0
        fallback_count = 0

        # Extract constants defined in the class
        class_constants = self._extract_class_constants(class_content)

        # Find all methods that return the builder type using a more robust approach
        # Split by method signature pattern and process each
        method_signature_pattern = rf'{re.escape(class_name)}\s+(\w+)\s*\([^)]*\)\s*\{{'

        # Find all method starts
        method_starts = []
        for match in re.finditer(method_signature_pattern, class_content):
            method_starts.append({
                'name': match.group(1),
                'start': match.end() - 1,  # Position of opening brace
                'signature_start': match.start()
            })

        # Extract method bodies by finding matching braces
        for i, method_info in enumerate(method_starts):
            method_name = method_info['name']
            start_pos = method_info['start']

            # Skip inherited pagination methods
            if method_name in ['cursor', 'limit', 'order']:
                continue

            # Find the matching closing brace for this method
            # Determine the end position (next method or end of content)
            if i + 1 < len(method_starts):
                end_pos = method_starts[i + 1]['signature_start']
            else:
                end_pos = len(class_content)

            # Extract the method body
            method_body = class_content[start_pos:end_pos]

            # Find matching brace within this section
            brace_count = 0
            body_end = 0
            for j, char in enumerate(method_body):
                if char == '{':
                    brace_count += 1
                elif char == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        body_end = j
                        break

            if body_end > 0:
                method_body = method_body[:body_end]

            # Try to extract parameter names from method body
            param_names = self._extract_query_parameters(method_body, class_constants)

            if param_names:
                # Successfully extracted parameter names dynamically
                for param_name in param_names:
                    filter_methods.append({
                        "method": method_name,
                        "parameter": param_name,
                        "detection": "dynamic"
                    })
                    dynamic_count += 1
                print(f"  [{class_name}] Detected filter method dynamically: {method_name} -> {param_names}")
            elif method_name in self.FILTER_PARAMETER_FALLBACK:
                # Fall back to hardcoded mapping
                param_name = self.FILTER_PARAMETER_FALLBACK[method_name]
                filter_methods.append({
                    "method": method_name,
                    "parameter": param_name,
                    "detection": "fallback"
                })
                fallback_count += 1
                print(f"  [{class_name}] Using fallback for filter method: {method_name} -> {param_name}")

        # Calculate confidence score
        total_count = dynamic_count + fallback_count
        confidence = dynamic_count / total_count if total_count > 0 else 1.0

        # Update stats
        if dynamic_count > 0 and fallback_count == 0:
            self.detection_stats["filters_dynamic"] += 1
        elif fallback_count > 0 and dynamic_count == 0:
            self.detection_stats["filters_fallback"] += 1
        elif dynamic_count > 0 and fallback_count > 0:
            self.detection_stats["filters_hybrid"] += 1

        return filter_methods, confidence

    def _extract_class_constants(self, class_content: str) -> Dict[str, str]:
        """
        Extract constant definitions from class content

        Looks for patterns like:
        static const String SIGNER_PARAMETER_NAME = "signer";
        """
        constants = {}

        # Pattern: static const String CONSTANT_NAME = "value";
        const_pattern = r'static\s+const\s+String\s+(\w+)\s*=\s*"([^"]+)"'
        for match in re.finditer(const_pattern, class_content):
            const_name = match.group(1)
            const_value = match.group(2)
            constants[const_name] = const_value

        return constants

    def _extract_query_parameters(
        self,
        method_body: str,
        class_constants: Optional[Dict[str, str]] = None
    ) -> Set[str]:
        """
        Extract query parameter names from method body

        Looks for patterns like:
        - queryParameters["param_name"]
        - queryParameters.addAll({"param": value})
        - {"param_name": value}
        - PARAMETER_NAME constants

        Args:
            method_body: The method body text
            class_constants: Dict of constant name -> value mappings
        """
        if class_constants is None:
            class_constants = {}

        param_names = set()

        # Pattern 1: queryParameters.addAll({...}) - extract all string keys
        # More permissive pattern that captures nested content
        dict_pattern = r'\{\s*"(\w+)"\s*:\s*'
        for match in re.finditer(dict_pattern, method_body):
            param_names.add(match.group(1))

        # Pattern 2: queryParameters["param"] = value
        bracket_pattern = r'queryParameters\s*\[\s*"(\w+)"\s*\]'
        for match in re.finditer(bracket_pattern, method_body):
            param_names.add(match.group(1))

        # Pattern 3: Using constants like {SIGNER_PARAMETER_NAME: value}
        const_usage_pattern = r'\{\s*(\w+_PARAMETER_NAME)\s*:\s*'
        for match in re.finditer(const_usage_pattern, method_body):
            const_name = match.group(1)
            if const_name in class_constants:
                param_names.add(class_constants[const_name])

        # Pattern 4: queryParameters.addAll({CONSTANT_NAME: value})
        const_bracket_pattern = r'queryParameters\s*\[\s*(\w+_PARAMETER_NAME)\s*\]'
        for match in re.finditer(const_bracket_pattern, method_body):
            const_name = match.group(1)
            if const_name in class_constants:
                param_names.add(class_constants[const_name])

        # Pattern 5: Handle complex asset parameters
        # baseAsset() sets base_asset_type, base_asset_code, base_asset_issuer
        # We normalize these to just the base parameter name
        if 'base_asset_type' in method_body or '"base_asset_code"' in method_body:
            # Remove individual components and add normalized name
            param_names.discard('base_asset_type')
            param_names.discard('base_asset_code')
            param_names.discard('base_asset_issuer')
            param_names.add('base_asset')

        if 'counter_asset_type' in method_body or '"counter_asset_code"' in method_body:
            param_names.discard('counter_asset_type')
            param_names.discard('counter_asset_code')
            param_names.discard('counter_asset_issuer')
            param_names.add('counter_asset')

        if 'selling_asset_type' in method_body or '"selling_asset_code"' in method_body:
            param_names.discard('selling_asset_type')
            param_names.discard('selling_asset_code')
            param_names.discard('selling_asset_issuer')
            param_names.add('selling_asset')

        if 'buying_asset_type' in method_body or '"buying_asset_code"' in method_body:
            param_names.discard('buying_asset_type')
            param_names.discard('buying_asset_code')
            param_names.discard('buying_asset_issuer')
            param_names.add('buying_asset')

        # Pattern 6: Handle complex source/destination asset parameters for path endpoints
        if 'source_asset_type' in method_body or '"source_asset_code"' in method_body:
            param_names.discard('source_asset_type')
            param_names.discard('source_asset_code')
            param_names.discard('source_asset_issuer')
            # Keep the actual parameter used (source_asset, not base_asset)

        if 'destination_asset_type' in method_body or '"destination_asset_code"' in method_body:
            param_names.discard('destination_asset_type')
            param_names.discard('destination_asset_code')
            param_names.discard('destination_asset_issuer')
            # Keep the actual parameter used (destination_asset)

        return param_names

    def _extract_methods(self, content: str, class_name: str) -> List[Dict[str, str]]:
        """Extract public methods from builder class"""
        methods = []

        # Pattern for method definitions
        # Future<Type> methodName(params) or Type methodName(params)
        method_pattern = r'(?:Future<)?(\w+(?:<\w+>)?)\??>\s+(\w+)\s*\([^)]*\)'

        for match in re.finditer(method_pattern, content):
            return_type = match.group(1)
            method_name = match.group(2)

            # Skip private methods and constructors
            if method_name.startswith('_') or method_name == class_name:
                continue

            # Skip inherited methods from RequestBuilder
            if method_name in ['cursor', 'limit', 'order', 'execute', 'buildUri',
                               'setSegments', 'forEndpoint']:
                continue

            methods.append({
                "name": method_name,
                "return_type": return_type
            })

        return methods

    def _build_sdk_methods_mapping(self) -> None:
        """Build SDK methods mapping for endpoint comparison"""
        # First, add direct endpoint implementations
        for endpoint_path, endpoint_info in self.direct_endpoints.items():
            # For POST endpoints, append the HTTP method to match the lookup key format
            if endpoint_info["http_method"] == "POST":
                key = f"{endpoint_path} ({endpoint_info['http_method']})"
            else:
                key = endpoint_path

            # Determine the class name
            method_name = endpoint_info["method"]
            if "." in method_name:
                class_name = method_name.split(".")[0]
            else:
                class_name = "StellarSDK"

            # Use notes from endpoint_info if provided
            notes = endpoint_info.get("notes", "")
            if not notes:
                notes = f"Implemented via {method_name}() method"
            else:
                notes = f"Implemented via {method_name}() method. {notes}"

            self.sdk_methods[key] = {
                "implemented": endpoint_info["implemented"],
                "sdk_method": method_name,
                "class": class_name,
                "streaming": False,
                "deprecated": False,
                "filters": [],
                "http_method": endpoint_info["http_method"],
                "notes": notes
            }

        # Then, add request builder implementations
        for builder in self.builders:
            for endpoint in builder.endpoints:
                # Determine if implemented
                implemented = builder.exposed_in_sdk

                # Build filters list - now with detection metadata stripped
                filters = [f["parameter"] for f in builder.filter_methods]

                # Add standard pagination filters if it's a list endpoint
                if not any(param in endpoint for param in ['{', '}']):
                    filters.extend(['cursor', 'limit', 'order'])

                # Check if endpoint already exists - apply priority rules
                if endpoint in self.sdk_methods:
                    existing = self.sdk_methods[endpoint]
                    # Priority: prefer builder whose name matches the endpoint
                    # e.g., LiquidityPoolsRequestBuilder for /liquidity_pools
                    #       not LiquidityPoolTradesRequestBuilder
                    endpoint_key = endpoint.strip('/').split('/')[0].replace('_', '')
                    existing_class = existing.get('class', '').lower()
                    new_class = builder.class_name.lower()

                    # If existing class matches better, skip
                    if endpoint_key in existing_class and endpoint_key not in new_class:
                        continue
                    # If new class doesn't match better, skip
                    if endpoint_key not in new_class and endpoint_key in existing_class:
                        continue

                # Determine SDK method name - include filter method for sub-resource endpoints
                base_sdk_method = builder.sdk_property if builder.sdk_property else builder.class_name
                sdk_method = self._get_sdk_method_for_endpoint(endpoint, base_sdk_method)
                filter_method = self._get_filter_method_for_endpoint(endpoint)
                if filter_method:
                    sdk_method = f"{base_sdk_method}.{filter_method}"

                self.sdk_methods[endpoint] = {
                    "implemented": implemented,
                    "sdk_method": sdk_method,
                    "class": builder.class_name,
                    "streaming": builder.streaming_support,
                    "deprecated": False,
                    "filters": list(set(filters)),
                    "notes": f"Implemented via {builder.class_name}" if implemented else ""
                }

                # Add sub-resource endpoints
                if endpoint.endswith('}'):
                    base_category = endpoint.split('/')[1]
                    sub_resources = self._get_sub_resources(base_category)

                    for sub_resource in sub_resources:
                        sub_endpoint = f"{endpoint}/{sub_resource}"
                        if sub_endpoint not in self.sdk_methods:
                            sub_builder = self._find_builder_for_endpoint(sub_endpoint)
                            if sub_builder:
                                # Get the filter method for this sub-resource endpoint
                                sub_filter_method = self._get_filter_method_for_endpoint(sub_endpoint)
                                sub_sdk_property = sub_builder.sdk_property if sub_builder.sdk_property else sub_builder.class_name
                                sub_sdk_method = f"{sub_sdk_property}.{sub_filter_method}" if sub_filter_method else sub_sdk_property

                                self.sdk_methods[sub_endpoint] = {
                                    "implemented": sub_builder.exposed_in_sdk,
                                    "sdk_method": sub_sdk_method,
                                    "class": sub_builder.class_name,
                                    "streaming": sub_builder.streaming_support,
                                    "deprecated": False,
                                    "filters": [f["parameter"] for f in sub_builder.filter_methods] + ['cursor', 'limit', 'order'],
                                    "notes": f"Implemented via {sub_builder.class_name}"
                                }

    def _get_sub_resources(self, category: str) -> List[str]:
        """Get common sub-resources for a category"""
        sub_resources = {
            "accounts": ["effects", "offers", "operations", "payments", "trades", "transactions"],
            "ledgers": ["effects", "operations", "payments", "transactions"],
            "liquidity_pools": ["effects", "operations", "trades", "transactions"],
            "claimable_balances": ["operations", "transactions"],
            "transactions": ["effects", "operations", "payments"],
            "operations": ["effects"],
        }
        return sub_resources.get(category, [])

    # Maps endpoint patterns to the filter method that enables them
    # Pattern: (category, sub_resource) -> filter_method_name
    ENDPOINT_FILTER_METHODS = {
        ("accounts", "effects"): "forAccount",
        ("accounts", "offers"): "forAccount",
        ("accounts", "operations"): "forAccount",
        ("accounts", "payments"): "forAccount",
        ("accounts", "trades"): "forAccount",
        ("accounts", "transactions"): "forAccount",
        ("accounts", "data"): "forAccount",
        ("ledgers", "effects"): "forLedger",
        ("ledgers", "operations"): "forLedger",
        ("ledgers", "payments"): "forLedger",
        ("ledgers", "transactions"): "forLedger",
        ("liquidity_pools", "effects"): "forLiquidityPool",
        ("liquidity_pools", "operations"): "forLiquidityPool",
        ("liquidity_pools", "trades"): "forPoolId",
        ("liquidity_pools", "transactions"): "forLiquidityPool",
        ("claimable_balances", "operations"): "forClaimableBalance",
        ("claimable_balances", "transactions"): "forClaimableBalance",
        ("transactions", "effects"): "forTransaction",
        ("transactions", "operations"): "forTransaction",
        ("transactions", "payments"): "forTransaction",
        ("operations", "effects"): "forOperation",
        ("offers", "trades"): "forOffer",
    }

    # Maps specific endpoint patterns to their SDK method names
    # These are methods that access specific resources by ID or with additional path params
    ENDPOINT_SDK_METHODS = {
        "/accounts/{account_id}": "account",
        "/accounts/{account_id}/data/{key}": "accountData",
        "/ledgers/{ledger_sequence}": "ledger",
        "/transactions/{transaction_id}": "transaction",
        "/operations/{operation_id}": "operation",
        "/offers/{offer_id}": "offer",
        "/claimable_balances/{claimable_balance_id}": "claimableBalance",
        "/liquidity_pools/{liquidity_pool_id}": "liquidityPool",
    }

    def _get_sdk_method_for_endpoint(self, endpoint: str, base_sdk_method: str) -> str:
        """Get the specific SDK method name for an endpoint"""
        # Check if there's a specific method for this endpoint pattern
        if endpoint in self.ENDPOINT_SDK_METHODS:
            return f"{base_sdk_method}.{self.ENDPOINT_SDK_METHODS[endpoint]}"
        return base_sdk_method

    def _get_filter_method_for_endpoint(self, endpoint: str) -> Optional[str]:
        """Get the filter method name that enables a sub-resource endpoint"""
        parts = endpoint.strip('/').split('/')
        if len(parts) >= 3:
            category = parts[0]
            sub_resource = parts[-1]
            return self.ENDPOINT_FILTER_METHODS.get((category, sub_resource))

    def _find_builder_for_endpoint(self, endpoint: str) -> Optional[RequestBuilderInfo]:
        """Find request builder that handles a specific endpoint"""
        parts = endpoint.strip('/').split('/')
        if len(parts) >= 3:
            resource = parts[-1]

            for builder in self.builders:
                if resource in [e.split('/')[-1] for e in builder.endpoints if '/' in e]:
                    return builder

        return None

    def to_json(self) -> Dict:
        """Convert analyzed data to JSON structure"""
        sdk_version = self._get_sdk_version()

        return {
            "metadata": {
                "sdk_version": sdk_version,
                "analyzed_at": datetime.now().isoformat(),
                "total_request_builders": len(self.builders),
                "exposed_builders": len(self.exposed_builders),
                "sdk_root": str(self.sdk_root),
                "detection_stats": self.detection_stats
            },
            "request_builders": [builder.to_dict() for builder in self.builders],
            "sdk_methods": self.sdk_methods
        }

    @staticmethod
    def _get_sdk_version() -> str:
        """Extract SDK version from pubspec.yaml."""
        return get_sdk_version()

    def save_json(self, output_path: str) -> None:
        """Save analyzed data to JSON file"""
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)

        data = self.to_json()

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

        print(f"Saved SDK analysis to: {output_path}")


def main():
    """Main entry point"""
    print("=" * 70)
    print("Flutter SDK Implementation Analyzer")
    print("=" * 70)
    print()

    # Define paths
    base_dir = Path(__file__).parent.parent.parent
    sdk_root = base_dir
    output_path = Path(__file__).parent / "data" / "horizon" / "flutter_sdk_implementation.json"

    try:
        # Analyze SDK
        analyzer = FlutterSDKAnalyzer(str(sdk_root))
        analyzer.analyze()

        # Save results
        analyzer.save_json(str(output_path))

        # Print summary
        print()
        print("=" * 70)
        print("SUMMARY")
        print("=" * 70)
        print(f"SDK Version: {analyzer._get_sdk_version()}")
        print(f"Total Request Builders: {len(analyzer.builders)}")
        print(f"Exposed in StellarSDK: {len(analyzer.exposed_builders)}")
        print()
        print("Request Builders:")
        for builder in sorted(analyzer.builders, key=lambda b: b.class_name):
            status = "✓" if builder.exposed_in_sdk else " "
            streaming = "S" if builder.streaming_support else " "
            detection = "D" if builder.endpoint_detection_source == DetectionSource.DYNAMIC.value else "F"
            confidence = f"{builder.filter_detection_confidence:.0%}"
            print(f"  [{status}] [{streaming}] [{detection}] {builder.class_name:40s} "
                  f"({len(builder.endpoints)} endpoints, {len(builder.filter_methods)} filters, {confidence} confidence)")
        print()
        print("Legend: [✓] = Exposed in SDK, [S] = Streaming support, [D] = Dynamic detection, [F] = Fallback")
        print()
        print("=" * 70)
        print("Analysis completed successfully!")
        print("=" * 70)

        return 0

    except Exception as e:
        print(f"\nERROR: {str(e)}")
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
