#!/usr/bin/env python3
"""
Stellar RPC API vs Flutter SDK Soroban Comparison Generator

This script compares the Stellar RPC API methods with the Flutter SDK Soroban implementation
and generates detailed comparison data including coverage statistics, gaps analysis,
and prioritized recommendations.

Author: Stellar Flutter SDK Team
License: Apache-2.0
"""

import json
import re
import sys
import traceback
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass, field
from enum import Enum

# Add parent dir to path for shared modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from common import get_sdk_version


class SupportStatus(Enum):
    """Support status for RPC methods"""
    FULLY_SUPPORTED = "✅ Fully Supported"
    PARTIALLY_SUPPORTED = "⚠️ Partially Supported"
    NOT_SUPPORTED = "❌ Not Supported"
    DEPRECATED = "🔄 Deprecated"


class Priority(Enum):
    """Priority levels for gaps and missing features"""
    CRITICAL = "Critical"
    HIGH = "High"
    MEDIUM = "Medium"
    LOW = "Low"


@dataclass
class ParameterComparison:
    """Comparison data for method parameters"""
    total: int = 0
    supported: int = 0
    missing: List[str] = field(default_factory=list)

    @property
    def percentage(self) -> float:
        """Calculate support percentage"""
        return (self.supported / self.total * 100) if self.total > 0 else 0.0


@dataclass
class ResponseFieldComparison:
    """Comparison data for response fields"""
    total: int = 0
    supported: int = 0
    missing: List[str] = field(default_factory=list)

    @property
    def percentage(self) -> float:
        """Calculate support percentage"""
        return (self.supported / self.total * 100) if self.total > 0 else 0.0


@dataclass
class MethodComparison:
    """Complete comparison data for a single RPC method"""
    rpc_method: str
    sdk_implementation: Dict[str, Any] = field(default_factory=dict)
    parameters: Dict[str, ParameterComparison] = field(default_factory=dict)
    response_fields: Optional[ResponseFieldComparison] = None
    status: str = SupportStatus.NOT_SUPPORTED.value
    notes: str = ""
    priority: str = Priority.MEDIUM.value

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization"""
        result = {
            "rpc_method": self.rpc_method,
            "sdk_implementation": self.sdk_implementation,
            "parameters": {
                "required": {
                    "total": self.parameters.get("required", ParameterComparison()).total,
                    "supported": self.parameters.get("required", ParameterComparison()).supported,
                    "missing": self.parameters.get("required", ParameterComparison()).missing,
                },
                "optional": {
                    "total": self.parameters.get("optional", ParameterComparison()).total,
                    "supported": self.parameters.get("optional", ParameterComparison()).supported,
                    "missing": self.parameters.get("optional", ParameterComparison()).missing,
                }
            },
            "status": self.status,
            "notes": self.notes,
            "priority": self.priority
        }

        # Add response fields if available
        if self.response_fields:
            result["response_fields"] = {
                "total": self.response_fields.total,
                "supported": self.response_fields.supported,
                "missing": self.response_fields.missing
            }

        return result


class RPCMethodExtractor:
    """Extract RPC methods from stellar-rpc protocol files"""

    # Import fallback method metadata from the parser module
    from rpc_parser import RPCMethodParser as _RPCMethodParser
    RPC_METHODS = _RPCMethodParser.METHOD_METADATA

    def __init__(self, rpc_protocol_path: str, rpc_methods_file: Optional[Path] = None):
        """
        Initialize with path to stellar-rpc protocol directory

        Args:
            rpc_protocol_path: Path to stellar-rpc protocol directory
            rpc_methods_file: Optional path to existing rpc_methods.json file
        """
        self.protocol_path = Path(rpc_protocol_path)
        self.rpc_methods_file = rpc_methods_file

    def load_methods_from_json(self) -> Optional[Dict[str, Any]]:
        """
        Load RPC methods from existing JSON file

        Returns:
            Dictionary containing methods and metadata, or None if file not found
        """
        if not self.rpc_methods_file or not self.rpc_methods_file.exists():
            return None

        try:
            with open(self.rpc_methods_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                # Validate structure
                if "methods" in data:
                    return data
        except (json.JSONDecodeError, IOError):
            pass

        return None

    def extract_methods(self) -> Dict[str, Any]:
        """
        Extract RPC methods and return structured data

        First attempts to load from JSON file, falls back to hardcoded methods
        """
        # Try loading from existing JSON file
        loaded_data = self.load_methods_from_json()
        if loaded_data:
            print("  ✓ Loaded RPC methods from existing JSON file")
            return loaded_data

        # Fallback to hardcoded methods
        print("  ℹ Using hardcoded RPC methods (JSON file not found)")
        return {
            "metadata": {
                "source": str(self.protocol_path),
                "generated_at": datetime.now().isoformat(),
                "total_methods": len(self.RPC_METHODS)
            },
            "methods": self.RPC_METHODS
        }


class SorobanSDKAnalyzer:
    """Analyze Flutter SDK Soroban implementation"""

    def __init__(self, soroban_server_path: str):
        """Initialize with path to soroban_server.dart"""
        self.server_path = Path(soroban_server_path)
        self.methods: Dict[str, Dict] = {}
        self.response_classes: Dict[str, List[str]] = {}

    def analyze(self) -> Dict[str, Any]:
        """Analyze Soroban SDK implementation"""
        if not self.server_path.exists():
            raise FileNotFoundError(f"Soroban server file not found: {self.server_path}")

        content = self.server_path.read_text()

        # Extract implemented methods
        self._extract_methods(content)

        # Extract response class fields
        self._extract_response_classes(content)

        return {
            "metadata": {
                "source": str(self.server_path),
                "analyzed_at": datetime.now().isoformat(),
                "total_methods": len(self.methods)
            },
            "implemented_methods": self.methods,
            "response_classes": self.response_classes
        }

    def _extract_method_body(self, content: str, method_start: int) -> str:
        """Extract complete method body by counting braces"""
        brace_count = 0
        in_method = False
        method_end = method_start

        for i in range(method_start, len(content)):
            char = content[i]
            if char == '{':
                brace_count += 1
                in_method = True
            elif char == '}':
                brace_count -= 1
                if in_method and brace_count == 0:
                    method_end = i + 1
                    break

        return content[method_start:method_end]

    def _extract_methods(self, content: str) -> None:
        """Extract implemented RPC methods from Soroban server"""
        # Pattern to match RPC method implementations
        # Future<ResponseType> methodName(...) async {
        pattern = r'Future<(\w+)>\s+(\w+)\s*\([^)]*\)\s+async\s*\{'

        for match in re.finditer(pattern, content):
            response_type = match.group(1)
            method_name = match.group(2)

            # Skip private methods
            if method_name.startswith('_'):
                continue

            # Check if this is an RPC method call
            method_start = match.start()
            # Find method body by counting braces
            method_body = self._extract_method_body(content, method_start)

            # Look for JsonRpcMethod call
            rpc_call_match = re.search(r'JsonRpcMethod\s*\(\s*"([^"]+)"', method_body)
            if rpc_call_match:
                rpc_method = rpc_call_match.group(1)

                # Extract parameters by analyzing the JsonRpcMethod call
                # Pass the full match object so we can extract the signature
                params = self._extract_rpc_params(content, method_body, method_start, match)

                self.methods[rpc_method] = {
                    "implemented": True,
                    "dart_method": method_name,
                    "response_type": response_type,
                    "parameters": params
                }

    def _extract_rpc_params(self, full_content: str, method_body: str, method_start: int, method_match: re.Match) -> List[Dict]:
        """Extract RPC parameters by analyzing the JsonRpcMethod call"""
        params = []

        # Look for JsonRpcMethod args pattern
        # Pattern 1: args: {'key': value, ...}
        direct_args_match = re.search(r'args:\s*\{([^}]+)\}', method_body)
        if direct_args_match:
            args_content = direct_args_match.group(1)
            # Extract parameter names from the map
            param_names = re.findall(r"['\"](\w+)['\"]:", args_content)
            for param_name in param_names:
                params.append({
                    "name": param_name,
                    "type": "direct",
                    "supported": True
                })
            return params

        # Pattern 2: args: request.getRequestArgs()
        request_args_match = re.search(r'args:\s*(\w+)\.getRequestArgs\(\)', method_body, re.DOTALL)
        if request_args_match:
            request_var = request_args_match.group(1)
            # Extract the method signature from the match object
            signature_end = full_content.find(')', method_start)
            if signature_end != -1:
                signature = full_content[method_start:signature_end + 1]
                # Extract request class type
                request_type_match = re.search(r'(\w+Request)\s+' + re.escape(request_var), signature)
                if request_type_match:
                    request_class = request_type_match.group(1)
                    # Extract parameters from the request class
                    params = self._extract_request_class_params(full_content, request_class)
                    return params

        # Pattern 3: Method takes direct parameters and constructs args inline
        # e.g., sendTransaction(Transaction transaction) → {'transaction': transactionEnvelopeXdr}
        # Look for inline parameter construction in the method body
        inline_params = self._extract_inline_params(method_body)
        if inline_params:
            return inline_params

        return params

    def _extract_request_class_params(self, content: str, request_class: str) -> List[Dict]:
        """Extract parameters from a request class definition"""
        params = []

        # Find the class definition
        class_pattern = rf'class\s+{re.escape(request_class)}\s*\{{'
        class_match = re.search(class_pattern, content)

        if not class_match:
            return params

        # Find the getRequestArgs method within the class
        class_start = class_match.end()

        # Find getRequestArgs method signature
        get_args_pattern = r'Map<String,\s*dynamic>\s+getRequestArgs\(\)\s*\{'
        get_args_match = re.search(get_args_pattern, content[class_start:])

        if not get_args_match:
            return params

        # Extract the complete method body using brace counting
        method_start = class_start + get_args_match.start()
        method_body = self._extract_method_body(content, method_start)

        # Extract parameter names from map['paramName'] = value patterns
        param_names = re.findall(r"map\[['\"](\w+)['\"]\]", method_body)
        for param_name in set(param_names):  # Use set to avoid duplicates
            params.append({
                "name": param_name,
                "type": "request_object",
                "supported": True
            })

        return params

    def _extract_inline_params(self, method_body: str) -> List[Dict]:
        """Extract parameters that are constructed inline in the method"""
        params = []

        # Look for JsonRpcMethod with inline map construction
        # Pattern: JsonRpcMethod("methodName", args: {'param': value})
        inline_match = re.search(r'JsonRpcMethod\([^,]+,\s*args:\s*\{([^}]+)\}', method_body)
        if inline_match:
            args_content = inline_match.group(1)
            param_names = re.findall(r"['\"](\w+)['\"]:", args_content)
            for param_name in param_names:
                params.append({
                    "name": param_name,
                    "type": "inline",
                    "supported": True
                })

        return params

    def _extract_response_classes(self, content: str) -> None:
        """
        Extract response class definitions and their fields from Dart code.

        Parses response classes like:
        class GetLatestLedgerResponse extends SorobanRpcResponse {
          String? id;
          int? protocolVersion;
          ...
        }
        """
        # Pattern to match response class definitions
        # Look for class definition and extract everything until we hit a constructor or factory
        class_pattern = r'class\s+((?:Get|Send)\w+Response)\s+extends\s+SorobanRpcResponse\s*\{'

        for class_match in re.finditer(class_pattern, content):
            class_name = class_match.group(1)
            class_start = class_match.end()

            # Find the end of the field declarations (before constructor/factory methods)
            # Look for first occurrence of constructor or factory methods (but NOT static)
            end_markers = [
                content.find(f'\n  {class_name}(', class_start),
                content.find('\n  factory ', class_start),
            ]

            # Filter out -1 (not found) and get the minimum
            end_markers = [pos for pos in end_markers if pos != -1]
            if not end_markers:
                # If no markers found, look for class end
                class_end = content.find('\n}', class_start)
            else:
                class_end = min(end_markers)

            if class_end == -1:
                continue

            class_body = content[class_start:class_end]

            # Extract field declarations
            # Pattern: Type? fieldName; or Type fieldName;
            # Match lines that define fields (not comments, not static)
            # Updated pattern to exclude lines starting with 'static'
            field_pattern = r'^\s*(?:///[^\n]*\n)*\s*(?!static\s)(?:final\s+)?(?:[\w<>,\s]+\??)\s+(\w+);'
            fields = []

            for field_match in re.finditer(field_pattern, class_body, re.MULTILINE):
                field_name = field_match.group(1)

                # Skip static constants (usually uppercase)
                if field_name and not field_name.isupper():
                    fields.append(field_name)

            # Map response class to RPC method name
            # GetLatestLedgerResponse -> getLatestLedger
            method_name = self._response_class_to_method_name(class_name)
            if method_name:
                self.response_classes[method_name] = fields

    def _response_class_to_method_name(self, class_name: str) -> Optional[str]:
        """
        Convert response class name to RPC method name.

        Examples:
            GetLatestLedgerResponse -> getLatestLedger
            GetHealthResponse -> getHealth
            SendTransactionResponse -> sendTransaction
        """
        # Remove 'Response' suffix
        if not class_name.endswith('Response'):
            return None

        base_name = class_name[:-8]  # Remove 'Response'

        # Convert to camelCase
        if base_name:
            return base_name[0].lower() + base_name[1:]

        return None


class RPCComparisonAnalyzer:
    """Main analyzer for comparing RPC API with Flutter SDK implementation"""

    # Optional parameters to ignore in compatibility checks
    # - xdrFormat: SDK doesn't support JSON format, only XDR (by design)
    # - cursor, limit: Standard pagination parameters handled by SDK via PaginationOptions class
    #   The SDK uses PaginationOptions object which adds cursor/limit to request args,
    #   but the simple regex analysis doesn't detect this pattern
    IGNORED_OPTIONAL_PARAMS = {"xdrFormat", "cursor", "limit"}

    def __init__(self, rpc_data: Dict[str, Any], flutter_data: Dict[str, Any]):
        """
        Initialize the analyzer with RPC and Flutter SDK data

        Args:
            rpc_data: Dictionary containing RPC methods data
            flutter_data: Dictionary containing Flutter SDK implementation data
        """
        self.rpc_data = rpc_data
        self.flutter_data = flutter_data
        self.comparisons: List[MethodComparison] = []
        self.sdk_version = self._get_sdk_version()

        # Extract RPC version information from metadata
        metadata = rpc_data.get("metadata", {})
        self.rpc_version = metadata.get("rpc_version", "Unknown")
        self.rpc_release_date = metadata.get("rpc_release_date", "Unknown")
        self.rpc_release_url = metadata.get("rpc_release_url", "")

    @staticmethod
    def _get_sdk_version() -> str:
        """Extract SDK version from pubspec.yaml."""
        return get_sdk_version()

    def analyze(self) -> None:
        """Perform complete comparison analysis"""
        rpc_methods = self.rpc_data.get("methods", {})
        flutter_methods = self.flutter_data.get("implemented_methods", {})
        flutter_response_classes = self.flutter_data.get("response_classes", {})

        for method_name, method_data in rpc_methods.items():
            comparison = self._compare_method(
                method_name,
                method_data,
                flutter_methods.get(method_name),
                flutter_response_classes.get(method_name, [])
            )
            self.comparisons.append(comparison)

    def _compare_method(
        self,
        method_name: str,
        rpc_method: Dict[str, Any],
        flutter_method: Optional[Dict[str, Any]],
        flutter_response_fields: List[str]
    ) -> MethodComparison:
        """Compare a single RPC method with its Flutter implementation"""
        comparison = MethodComparison(rpc_method=method_name)

        # Check if method is implemented in Flutter SDK
        if not flutter_method or not flutter_method.get("implemented", False):
            comparison.status = SupportStatus.NOT_SUPPORTED.value
            comparison.priority = self._determine_priority(method_name, None)
            comparison.notes = "Method not implemented in Flutter SDK"
            comparison.sdk_implementation = {
                "implemented": False,
                "dart_method": None,
                "response_type": None
            }

            # Count all parameters as missing
            comparison.parameters["required"] = ParameterComparison(
                total=len(rpc_method.get("required_params", [])),
                supported=0,
                missing=rpc_method.get("required_params", [])
            )
            comparison.parameters["optional"] = ParameterComparison(
                total=len(rpc_method.get("optional_params", [])),
                supported=0,
                missing=rpc_method.get("optional_params", [])
            )

            # Count all response fields as missing
            rpc_response_fields = rpc_method.get("response_fields", [])
            if rpc_response_fields:
                comparison.response_fields = ResponseFieldComparison(
                    total=len(rpc_response_fields),
                    supported=0,
                    missing=[f["json_name"] for f in rpc_response_fields]
                )

            return comparison

        # Method is implemented - check parameters
        comparison.sdk_implementation = {
            "implemented": True,
            "dart_method": flutter_method.get("dart_method", method_name),
            "response_type": flutter_method.get("response_type")
        }

        # Compare parameters
        comparison.parameters = self._compare_parameters(
            rpc_method,
            flutter_method.get("parameters", [])
        )

        # Compare response fields
        rpc_response_fields = rpc_method.get("response_fields", [])
        if rpc_response_fields:
            comparison.response_fields = self._compare_response_fields(
                rpc_response_fields,
                flutter_response_fields
            )

        # Determine status
        comparison.status, comparison.notes = self._determine_status(comparison)
        comparison.priority = self._determine_priority(method_name, comparison)

        return comparison

    def _compare_parameters(
        self,
        rpc_method: Dict[str, Any],
        flutter_params: List[Dict[str, Any]]
    ) -> Dict[str, ParameterComparison]:
        """Compare required and optional parameters"""
        result = {}
        flutter_param_names = {p["name"] for p in flutter_params if p.get("supported", False)}

        for param_type in ["required", "optional"]:
            rpc_param_list = rpc_method.get(f"{param_type}_params", [])

            # Filter out ignored optional parameters
            if param_type == "optional":
                rpc_param_list = [p for p in rpc_param_list if p not in self.IGNORED_OPTIONAL_PARAMS]

            total = len(rpc_param_list)
            supported_params = []
            missing_params = []

            for param in rpc_param_list:
                if param in flutter_param_names:
                    supported_params.append(param)
                else:
                    missing_params.append(param)

            result[param_type] = ParameterComparison(
                total=total,
                supported=len(supported_params),
                missing=missing_params
            )

        return result

    def _compare_response_fields(
        self,
        rpc_response_fields: List[Dict[str, str]],
        flutter_response_fields: List[str]
    ) -> ResponseFieldComparison:
        """
        Compare RPC response fields with Flutter SDK response class fields.

        Args:
            rpc_response_fields: List of dicts with field_name and json_name from RPC
            flutter_response_fields: List of field names from Flutter SDK response class

        Returns:
            ResponseFieldComparison with total, supported, and missing counts
        """
        # Convert Flutter field names to lowercase for case-insensitive comparison
        flutter_field_map = {name.lower(): name for name in flutter_response_fields}

        # Create mapping of JSON name to Go field name for better error reporting
        json_to_go_field = {f["json_name"]: f["field_name"] for f in rpc_response_fields}

        total = len(rpc_response_fields)
        supported_fields = []
        missing_fields = []

        for rpc_field in rpc_response_fields:
            json_name = rpc_field["json_name"]

            # Check if this field exists in Flutter SDK (case-insensitive)
            # Try both camelCase and the original JSON name
            if json_name.lower() in flutter_field_map:
                supported_fields.append(json_name)
            else:
                missing_fields.append(json_name)

        return ResponseFieldComparison(
            total=total,
            supported=len(supported_fields),
            missing=missing_fields
        )

    def _determine_status(self, comparison: MethodComparison) -> Tuple[str, str]:
        """Determine the implementation status based on parameter and response field support"""
        required_params = comparison.parameters.get("required", ParameterComparison())
        optional_params = comparison.parameters.get("optional", ParameterComparison())
        response_fields = comparison.response_fields

        issues = []

        # Check if all required parameters are supported
        if required_params.missing:
            issues.append(f"Missing required parameters: {', '.join(required_params.missing)}")

        # Check optional parameters
        if optional_params.missing:
            issues.append(f"Missing optional parameters: {', '.join(optional_params.missing)}")

        # Check response fields
        if response_fields and response_fields.missing:
            issues.append(f"Missing response fields: {', '.join(response_fields.missing)}")

        if issues:
            return SupportStatus.PARTIALLY_SUPPORTED.value, "; ".join(issues)

        return SupportStatus.FULLY_SUPPORTED.value, "All parameters and response fields implemented"

    def _determine_priority(
        self,
        method_name: str,
        comparison: Optional[MethodComparison]
    ) -> str:
        """Determine priority level for implementation or fixes"""
        # Critical methods - core functionality
        critical_methods = {
            "sendTransaction", "simulateTransaction", "getTransaction",
            "getLedgerEntries", "getNetwork", "getHealth"
        }

        # High priority - important for development
        high_priority_methods = {
            "getEvents", "getLatestLedger", "getFeeStats", "getTransactions", "getLedgers"
        }

        # If method is not implemented at all
        if not comparison or comparison.status == SupportStatus.NOT_SUPPORTED.value:
            if method_name in critical_methods:
                return Priority.CRITICAL.value
            if method_name in high_priority_methods:
                return Priority.HIGH.value
            return Priority.MEDIUM.value

        # If method has missing required parameters
        required_params = comparison.parameters.get("required", ParameterComparison())
        if required_params.missing:
            return Priority.CRITICAL.value

        # If method is partially supported
        if comparison.status == SupportStatus.PARTIALLY_SUPPORTED.value:
            if method_name in critical_methods:
                return Priority.HIGH.value
            return Priority.MEDIUM.value

        # Fully supported
        return Priority.LOW.value

    def generate_comparison_data(self) -> Dict[str, Any]:
        """Generate complete comparison data structure"""
        return {
            "metadata": {
                "rpc_methods": len(self.rpc_data.get("methods", {})),
                "sdk_methods": len(self.flutter_data.get("implemented_methods", {})),
                "comparison_date": datetime.now().isoformat(),
                "coverage_percentage": self._calculate_overall_coverage(),
                "rpc_version": self.rpc_version,
                "rpc_release_date": self.rpc_release_date,
                "rpc_release_url": self.rpc_release_url,
                "sdk_version": self.sdk_version
            },
            "method_comparison": [comp.to_dict() for comp in self.comparisons],
            "gaps": self._generate_gaps_summary()
        }

    def _calculate_overall_coverage(self) -> float:
        """Calculate overall coverage percentage"""
        if not self.comparisons:
            return 0.0

        fully_supported = sum(
            1 for c in self.comparisons
            if c.status == SupportStatus.FULLY_SUPPORTED.value
        )
        return round(fully_supported / len(self.comparisons) * 100, 2)

    def _generate_gaps_summary(self) -> Dict[str, Any]:
        """Generate summary of gaps and missing features"""
        missing_methods = []
        partial_implementations = []

        for comp in self.comparisons:
            if comp.status == SupportStatus.NOT_SUPPORTED.value:
                missing_methods.append({
                    "method": comp.rpc_method,
                    "priority": comp.priority
                })
            elif comp.status == SupportStatus.PARTIALLY_SUPPORTED.value:
                partial_implementations.append({
                    "method": comp.rpc_method,
                    "priority": comp.priority,
                    "notes": comp.notes
                })

        return {
            "missing_methods": missing_methods,
            "partial_implementations": partial_implementations
        }

    def generate_coverage_stats(self) -> Dict[str, Any]:
        """Generate detailed coverage statistics"""
        total_methods = len(self.comparisons)
        fully_supported = sum(
            1 for c in self.comparisons
            if c.status == SupportStatus.FULLY_SUPPORTED.value
        )
        partially_supported = sum(
            1 for c in self.comparisons
            if c.status == SupportStatus.PARTIALLY_SUPPORTED.value
        )
        not_supported = sum(
            1 for c in self.comparisons
            if c.status == SupportStatus.NOT_SUPPORTED.value
        )

        # Parameter stats
        required_total = sum(
            c.parameters.get("required", ParameterComparison()).total
            for c in self.comparisons
        )
        required_supported = sum(
            c.parameters.get("required", ParameterComparison()).supported
            for c in self.comparisons
        )

        # Gaps by priority
        gaps_by_priority = {
            "critical": [],
            "high": [],
            "medium": [],
            "low": []
        }

        for comp in self.comparisons:
            if comp.status != SupportStatus.FULLY_SUPPORTED.value:
                priority_key = comp.priority.lower()
                gaps_by_priority[priority_key].append({
                    "method": comp.rpc_method,
                    "status": comp.status,
                    "notes": comp.notes
                })

        return {
            "overall": {
                "total_methods": total_methods,
                "fully_supported": fully_supported,
                "partially_supported": partially_supported,
                "not_supported": not_supported,
                "coverage_percentage": round(
                    fully_supported / total_methods * 100 if total_methods > 0 else 0,
                    2
                )
            },
            "parameters": {
                "required_total": required_total,
                "required_supported": required_supported,
                "required_percentage": round(
                    required_supported / required_total * 100 if required_total > 0 else 0,
                    2
                )
            },
            "gaps_by_priority": gaps_by_priority
        }

    def generate_markdown_report(self, output_path: str) -> None:
        """Generate markdown compatibility report"""
        stats = self.generate_coverage_stats()
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)

        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("# Soroban RPC vs Flutter SDK Compatibility Matrix\n\n")

            # Version information section
            f.write(f"**RPC Version:** {self.rpc_version}")
            if self.rpc_release_date != "Unknown":
                f.write(f" (released {self.rpc_release_date})")
            f.write("  \n")

            if self.rpc_release_url:
                f.write(f"**RPC Source:** [{self.rpc_release_url}]({self.rpc_release_url})  \n")

            f.write(f"**SDK Version:** {self.sdk_version}  \n")
            f.write(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

            # Overall Statistics
            f.write("## Overall Coverage\n\n")
            overall = stats['overall']
            f.write(f"**Coverage:** {overall['coverage_percentage']}%\n\n")
            f.write(f"- ✅ **Fully Supported:** {overall['fully_supported']}/{overall['total_methods']}\n")
            f.write(f"- ⚠️ **Partially Supported:** {overall['partially_supported']}/{overall['total_methods']}\n")
            f.write(f"- ❌ **Not Supported:** {overall['not_supported']}/{overall['total_methods']}\n\n")

            # Method Comparison
            f.write("## Method Comparison\n\n")
            f.write("| RPC Method | Status | Flutter Method | Required Params | Response Fields | Notes |\n")
            f.write("|------------|--------|----------------|-----------------|-----------------|-------|\n")

            for comp in sorted(self.comparisons, key=lambda x: x.rpc_method):
                dart_method = comp.sdk_implementation.get("dart_method", "-")
                required = comp.parameters.get("required", ParameterComparison())
                param_status = f"{required.supported}/{required.total}" if required.total > 0 else "N/A"

                # Add response fields status
                if comp.response_fields:
                    response_status = f"{comp.response_fields.supported}/{comp.response_fields.total}"
                else:
                    response_status = "N/A"

                f.write(f"| `{comp.rpc_method}` | {comp.status} | "
                       f"`{dart_method}` | {param_status} | {response_status} | {comp.notes} |\n")

            f.write("\n")

            # Response Field Coverage Detail
            f.write("## Response Field Coverage\n\n")
            f.write("Detailed breakdown of response field support per method.\n\n")
            f.write("| RPC Method | RPC Fields | SDK Fields | Missing Fields |\n")
            f.write("|------------|------------|------------|----------------|\n")

            for comp in sorted(self.comparisons, key=lambda x: x.rpc_method):
                if comp.response_fields and comp.response_fields.total > 0:
                    missing_list = ", ".join(comp.response_fields.missing) if comp.response_fields.missing else "-"
                    f.write(f"| `{comp.rpc_method}` | {comp.response_fields.total} | "
                           f"{comp.response_fields.supported} | {missing_list} |\n")

            f.write("\n")

            # Implementation Gaps - only show if there are gaps
            gaps = stats['gaps_by_priority']
            total_gaps = sum(len(gaps[p]) for p in gaps)

            if total_gaps > 0:
                f.write("## Implementation Gaps\n\n")

                for priority in ["critical", "high", "medium", "low"]:
                    priority_gaps = gaps[priority]
                    if priority_gaps:
                        icon = {"critical": "🔴", "high": "🟠", "medium": "🟡", "low": "🟢"}
                        f.write(f"### {icon[priority]} {priority.title()} Priority ({len(priority_gaps)} items)\n\n")

                        for gap in priority_gaps:
                            f.write(f"- `{gap['method']}` - {gap['status']}\n")
                            if gap['notes']:
                                f.write(f"  - {gap['notes']}\n")

                        f.write("\n")

        print(f"✓ Markdown report written to {output_path}")


def main():
    """Main execution function"""
    print("=" * 70)
    print("Stellar RPC API vs Flutter SDK Comparison Generator")
    print("=" * 70)
    print()

    # Define paths
    sdk_root = Path(__file__).parent.parent.parent.parent
    base_dir = sdk_root / 'compatibility'
    rpc_protocol_path = sdk_root.parent / "stellar-rpc" / "protocol"
    soroban_server_path = sdk_root / "lib" / "src" / "soroban" / "soroban_server.dart"

    data_dir = Path(__file__).parent.parent / "data" / "rpc"
    rpc_methods_file = data_dir / "rpc_methods.json"
    flutter_implementation_file = data_dir / "flutter_soroban_implementation.json"
    comparison_output_file = data_dir / "rpc_comparison.json"
    stats_output_file = data_dir / "rpc_coverage_stats.json"
    markdown_output_file = base_dir / "rpc" / "RPC_COMPATIBILITY_MATRIX.md"

    try:
        # Extract RPC methods
        print(f"Extracting RPC methods from: {rpc_protocol_path}")
        rpc_extractor = RPCMethodExtractor(str(rpc_protocol_path), rpc_methods_file)
        rpc_data = rpc_extractor.extract_methods()

        # Save RPC methods
        data_dir.mkdir(parents=True, exist_ok=True)
        with open(rpc_methods_file, 'w', encoding='utf-8') as f:
            json.dump(rpc_data, f, indent=2, ensure_ascii=False)
        print(f"✓ Saved RPC methods to: {rpc_methods_file}")

        # Analyze Flutter Soroban implementation
        print(f"\nAnalyzing Flutter Soroban implementation: {soroban_server_path}")
        soroban_analyzer = SorobanSDKAnalyzer(str(soroban_server_path))
        flutter_data = soroban_analyzer.analyze()

        # Save Flutter implementation
        with open(flutter_implementation_file, 'w', encoding='utf-8') as f:
            json.dump(flutter_data, f, indent=2, ensure_ascii=False)
        print(f"✓ Saved Flutter implementation to: {flutter_implementation_file}")

        # Perform comparison
        print("\nAnalyzing compatibility...")
        analyzer = RPCComparisonAnalyzer(rpc_data, flutter_data)
        analyzer.analyze()

        # Generate comparison data
        comparison_data = analyzer.generate_comparison_data()
        with open(comparison_output_file, 'w', encoding='utf-8') as f:
            json.dump(comparison_data, f, indent=2, ensure_ascii=False)
        print(f"✓ Saved comparison to: {comparison_output_file}")

        # Generate coverage statistics
        coverage_stats = analyzer.generate_coverage_stats()
        with open(stats_output_file, 'w', encoding='utf-8') as f:
            json.dump(coverage_stats, f, indent=2, ensure_ascii=False)
        print(f"✓ Saved statistics to: {stats_output_file}")

        # Generate markdown report
        analyzer.generate_markdown_report(str(markdown_output_file))

        # Print summary
        print("\n" + "=" * 70)
        print("SUMMARY")
        print("=" * 70)
        metadata = comparison_data['metadata']
        print(f"RPC Version: {metadata['rpc_version']}")
        if metadata['rpc_release_date'] != "Unknown":
            print(f"RPC Release Date: {metadata['rpc_release_date']}")
        print(f"SDK Version: {metadata['sdk_version']}")
        print()
        print(f"Total RPC Methods: {metadata['rpc_methods']}")
        print(f"SDK Methods: {metadata['sdk_methods']}")
        print(f"Overall Coverage: {metadata['coverage_percentage']}%")
        print()

        overall = coverage_stats['overall']
        print(f"✅ Fully Supported: {overall['fully_supported']}")
        print(f"⚠️  Partially Supported: {overall['partially_supported']}")
        print(f"❌ Not Supported: {overall['not_supported']}")
        print()

        gaps = comparison_data['gaps']
        if gaps['missing_methods']:
            print(f"Missing Methods: {len(gaps['missing_methods'])}")
        if gaps['partial_implementations']:
            print(f"Partial Implementations: {len(gaps['partial_implementations'])}")

        print()
        print("=" * 70)
        print("✓ Comparison completed successfully!")
        print("=" * 70)

        return 0

    except FileNotFoundError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    except json.JSONDecodeError as e:
        print(f"ERROR: Invalid JSON: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"ERROR: Unexpected error: {e}", file=sys.stderr)
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
