#!/usr/bin/env python3
"""
Soroban RPC Method Parser

Parses Soroban RPC method definitions from Go source code (jsonrpc.go).
Extracts method names, descriptions, and parameter information for API compatibility analysis.

This module provides tools to:
- Parse RPC method registrations from Go source code
- Extract method names following the pattern: protocol.GetXxxMethodName -> getXxx
- Generate structured JSON output with method metadata
- Support both local file and GitHub-based parsing
"""

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any


class RPCMethodParser:
    """
    Parser for Soroban RPC method definitions from Go source code.

    This parser extracts RPC method names from the jsonrpc.go file,
    which contains method registrations in the form:
    {
        methodName: protocol.GetHealthMethodName,
        ...
    }

    Attributes:
        version_info: Optional version metadata for the RPC release
        methods: Dictionary of parsed method definitions
    """

    # Method pattern: methodName: protocol.XxxMethodName
    METHOD_PATTERN = re.compile(
        r'methodName:\s*protocol\.(\w+)MethodName',
        re.MULTILINE
    )

    # Pattern to match response struct definition
    # Example: type GetLatestLedgerResponse struct {
    RESPONSE_STRUCT_PATTERN = re.compile(
        r'type\s+(\w+Response)\s+struct\s*\{([^}]+)\}',
        re.MULTILINE | re.DOTALL
    )

    # Pattern to match struct field with JSON tag
    # Example: Hash string `json:"id"`
    # Handles tags like: `json:"field"`, `json:"field,omitempty"`, `json:"field,string"`
    STRUCT_FIELD_PATTERN = re.compile(
        r'(\w+)\s+[\w\.\*\[\]]+\s+`json:"([^,"]+)(?:,[^"]*)?"`'
    )

    # Known method descriptions and parameters
    # This serves as fallback data since parsing Go structs for parameters is complex
    METHOD_METADATA: Dict[str, Dict[str, Any]] = {
        "getHealth": {
            "description": "General node health check",
            "required_params": [],
            "optional_params": []
        },
        "getEvents": {
            "description": "Get filtered list of events",
            "required_params": ["startLedger"],
            "optional_params": ["endLedger", "filters", "pagination", "xdrFormat"]
        },
        "getNetwork": {
            "description": "General info about the configured network",
            "required_params": [],
            "optional_params": []
        },
        "getVersionInfo": {
            "description": "Version information about the RPC and Captive core",
            "required_params": [],
            "optional_params": []
        },
        "getLatestLedger": {
            "description": "Current latest known ledger",
            "required_params": [],
            "optional_params": []
        },
        "getLedgers": {
            "description": "Get detailed list of ledgers",
            "required_params": ["startLedger"],
            "optional_params": ["pagination", "xdrFormat"]
        },
        "getLedgerEntries": {
            "description": "Read ledger entry values",
            "required_params": ["keys"],
            "optional_params": ["xdrFormat"]
        },
        "getTransaction": {
            "description": "Get transaction status and details",
            "required_params": ["hash"],
            "optional_params": ["xdrFormat"]
        },
        "getTransactions": {
            "description": "Get detailed list of transactions",
            "required_params": ["startLedger"],
            "optional_params": ["pagination", "xdrFormat"]
        },
        "sendTransaction": {
            "description": "Submit a transaction to the network",
            "required_params": ["transaction"],
            "optional_params": []
        },
        "simulateTransaction": {
            "description": "Submit a trial contract invocation",
            "required_params": ["transaction"],
            "optional_params": ["resourceConfig", "authMode"]
        },
        "getFeeStats": {
            "description": "Statistics for charged inclusion fees",
            "required_params": [],
            "optional_params": []
        }
    }

    def __init__(self, version_info: Optional[Dict[str, str]] = None) -> None:
        """
        Initialize the RPC method parser.

        Args:
            version_info: Optional dictionary containing version metadata:
                - version: RPC version (e.g., "v22.0.0")
                - release_date: Release date (ISO format)
                - release_url: GitHub release URL
        """
        self.version_info = version_info or {}
        self.methods: Dict[str, Dict[str, Any]] = {}
        self._source_type: str = "Unknown"

    def parse(self, content: str) -> "RPCMethodParser":
        """
        Parse Go source code content to extract RPC method definitions.

        This method searches for method registrations in the form:
        methodName: protocol.GetHealthMethodName

        And converts them to camelCase method names:
        GetHealthMethodName -> getHealth

        Args:
            content: Go source code content from jsonrpc.go

        Returns:
            Self for method chaining

        Raises:
            ValueError: If no methods are found in the content
        """
        self.methods.clear()
        matches = self.METHOD_PATTERN.findall(content)

        if not matches:
            raise ValueError(
                "No RPC method registrations found in source. "
                "Expected pattern: methodName: protocol.XxxMethodName"
            )

        for match in matches:
            method_name = self._convert_method_name(match)
            if method_name:
                self.methods[method_name] = self._get_method_metadata(method_name)

        return self

    def parse_from_file(self, file_path: str) -> "RPCMethodParser":
        """
        Parse RPC method definitions from a local Go source file.

        Args:
            file_path: Path to the jsonrpc.go file

        Returns:
            Self for method chaining

        Raises:
            FileNotFoundError: If the file does not exist
            ValueError: If no methods are found in the file
        """
        path = Path(file_path)
        if not path.exists():
            raise FileNotFoundError(f"File not found: {file_path}")

        self._source_type = "Local"
        content = path.read_text(encoding="utf-8")
        return self.parse(content)

    def _convert_method_name(self, protocol_name: str) -> Optional[str]:
        """
        Convert protocol method name to camelCase RPC method name.

        The regex captures just the base name (e.g., "GetHealth"), not the full
        constant name (e.g., "GetHealthMethodName").

        Examples:
            GetHealth -> getHealth
            GetLatestLedger -> getLatestLedger
            SendTransaction -> sendTransaction

        Args:
            protocol_name: Protocol base name (e.g., GetHealth)

        Returns:
            camelCase method name or None if conversion fails
        """
        # Convert PascalCase to camelCase
        if protocol_name:
            return protocol_name[0].lower() + protocol_name[1:]

        return None

    def _get_method_metadata(self, method_name: str) -> Dict[str, Any]:
        """
        Get metadata for a method from the known metadata dictionary.

        Args:
            method_name: The camelCase method name

        Returns:
            Dictionary containing method description and parameters
        """
        if method_name in self.METHOD_METADATA:
            return self.METHOD_METADATA[method_name].copy()

        # Fallback for unknown methods
        return {
            "description": f"RPC method: {method_name}",
            "required_params": [],
            "optional_params": []
        }

    def parse_response_fields(self, response_content: str) -> List[Dict[str, str]]:
        """
        Parse response struct fields from Go source code.

        Args:
            response_content: Go source code containing response struct definition

        Returns:
            List of dictionaries with field name and JSON tag
            Example: [{"field_name": "Hash", "json_name": "id"}, ...]
        """
        fields = []

        # Find the response struct
        struct_match = self.RESPONSE_STRUCT_PATTERN.search(response_content)
        if not struct_match:
            return fields

        struct_body = struct_match.group(2)

        # Extract all fields with JSON tags
        for field_match in self.STRUCT_FIELD_PATTERN.finditer(struct_body):
            field_name = field_match.group(1)
            json_name = field_match.group(2)

            # Skip fields with special JSON tags
            if json_name in ["-", ""]:
                continue

            fields.append({
                "field_name": field_name,
                "json_name": json_name
            })

        return fields

    def add_response_fields_to_method(self, method_name: str, response_content: str) -> None:
        """
        Parse and add response fields to an existing method.

        Args:
            method_name: The camelCase method name (e.g., "getLatestLedger")
            response_content: Go source code containing the response struct
        """
        if method_name not in self.methods:
            return

        response_fields = self.parse_response_fields(response_content)
        self.methods[method_name]["response_fields"] = response_fields

    def to_json(self) -> Dict[str, Any]:
        """
        Convert parsed methods to structured JSON format.

        Returns:
            Dictionary containing metadata and method definitions
        """
        return {
            "metadata": {
                "source": self._source_type,
                "generated_at": datetime.now().isoformat(),
                "rpc_version": self.version_info.get("version", "unknown"),
                "rpc_release_date": self.version_info.get("release_date", "unknown"),
                "rpc_release_url": self.version_info.get("release_url", ""),
                "total_methods": len(self.methods)
            },
            "methods": self.methods
        }

    def save_json(self, output_path: str) -> None:
        """
        Save parsed methods to a JSON file.

        Args:
            output_path: Path where the JSON file should be written

        Raises:
            IOError: If the file cannot be written
        """
        path = Path(output_path)
        path.parent.mkdir(parents=True, exist_ok=True)

        data = self.to_json()
        with path.open("w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)

        print(f"Successfully saved {len(self.methods)} methods to: {output_path}")

    def get_method_count(self) -> int:
        """
        Get the number of parsed methods.

        Returns:
            Count of methods
        """
        return len(self.methods)

    def get_method_names(self) -> List[str]:
        """
        Get sorted list of method names.

        Returns:
            Sorted list of method names
        """
        return sorted(self.methods.keys())


def main() -> int:
    """
    Command-line interface for the RPC method parser.

    Returns:
        Exit code (0 for success, non-zero for failure)
    """
    parser = argparse.ArgumentParser(
        description="Parse Soroban RPC method definitions from Go source code",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Parse from local file
  python rpc_parser.py --local /path/to/jsonrpc.go --output rpc_methods.json
        """
    )

    parser.add_argument(
        "--local",
        metavar="PATH",
        required=True,
        help="Path to local jsonrpc.go file"
    )

    parser.add_argument(
        "--output",
        "-o",
        default="rpc_methods.json",
        help="Output JSON file path (default: rpc_methods.json)"
    )

    parser.add_argument(
        "--version",
        help="RPC version tag (e.g., v22.0.0)"
    )

    parser.add_argument(
        "--release-date",
        help="RPC release date (ISO format: YYYY-MM-DD)"
    )

    parser.add_argument(
        "--release-url",
        help="GitHub release URL"
    )

    args = parser.parse_args()

    # Prepare version info
    version_info = {}
    if args.version:
        version_info["version"] = args.version
    if args.release_date:
        version_info["release_date"] = args.release_date
    if args.release_url:
        version_info["release_url"] = args.release_url

    try:
        rpc_parser = RPCMethodParser(version_info=version_info if version_info else None)

        print(f"Parsing local file: {args.local}")
        rpc_parser.parse_from_file(args.local)

        # Display summary
        method_names = rpc_parser.get_method_names()
        print(f"\nFound {rpc_parser.get_method_count()} RPC methods:")
        for name in method_names:
            print(f"  - {name}")

        # Save to file
        print(f"\nSaving to: {args.output}")
        rpc_parser.save_json(args.output)

        return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
