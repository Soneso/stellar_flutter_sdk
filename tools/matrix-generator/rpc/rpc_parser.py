#!/usr/bin/env python3
"""
Soroban RPC Method Parser

Parses Soroban RPC method definitions from Go source code (jsonrpc.go).
Extracts method names, descriptions, and parameter information for API compatibility analysis.

This module provides tools to:
- Parse RPC method registrations from Go source code
- Extract method names following the pattern: protocol.GetXxxMethodName -> getXxx
- Generate structured JSON output with method metadata

Pipeline module of rpc/run_rpc_analysis.py, which supplies the source and the
release metadata.
"""

import json
import re
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
        version_info: Version metadata for the RPC release
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

    # Embedded struct: a struct body line that holds only a type name
    EMBEDDED_STRUCT_PATTERN = re.compile(r'\s+(\w+)\s*')

    # Description and parameters of each method; jsonrpc.go registers only the
    # method names, and the request structs are not parsed.
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

    def __init__(self, version_info: Dict[str, str]) -> None:
        """
        Initialize the RPC method parser.

        Args:
            version_info: Version metadata of the RPC release:
                - version: RPC version (e.g., "v28.0.1")
                - release_date: Release date (ISO format)
                - release_url: GitHub release URL
        """
        self.version_info = version_info
        self.methods: Dict[str, Dict[str, Any]] = {}

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

    def parse_response_fields(self, response_content: str, sources: List[str]) -> List[Dict[str, str]]:
        """
        Parse response struct fields from Go source code.

        An embedded struct contributes its fields in its place. It resolves
        across sources, since a response can embed a struct that another
        method's protocol file declares (GetTransactionResponse embeds
        TransactionDetails from get_transactions.go).

        Args:
            response_content: Go source code containing response struct definition
            sources: Go sources of every fetched protocol file

        Returns:
            List of dictionaries with field name and JSON tag
            Example: [{"field_name": "Hash", "json_name": "id"}, ...]

        Raises:
            ValueError: If no source declares an embedded struct
        """
        struct_match = self.RESPONSE_STRUCT_PATTERN.search(response_content)
        if not struct_match:
            return []
        return self._struct_fields(struct_match.group(1), struct_match.group(2), sources)

    def _struct_fields(self, struct_name: str, struct_body: str,
                       sources: List[str]) -> List[Dict[str, str]]:
        """JSON-tagged fields of a struct body, the fields of embedded structs included."""
        fields = []
        for line in struct_body.splitlines():
            embedded = self.EMBEDDED_STRUCT_PATTERN.fullmatch(line)
            if embedded:
                pattern = re.compile(rf'type\s+{embedded.group(1)}\s+struct\s*\{{([^}}]+)\}}')
                body = next((m.group(1) for m in map(pattern.search, sources) if m), None)
                if body is None:
                    raise ValueError(
                        f"{struct_name} embeds {embedded.group(1)}, which no fetched protocol "
                        f"file declares")
                fields.extend(self._struct_fields(embedded.group(1), body, sources))
                continue
            field_match = self.STRUCT_FIELD_PATTERN.search(line)
            # Skip fields with special JSON tags
            if field_match and field_match.group(2) not in ("-", ""):
                fields.append({"field_name": field_match.group(1), "json_name": field_match.group(2)})
        return fields

    def add_response_fields_to_method(self, method_name: str, response_content: str,
                                      sources: List[str]) -> None:
        """
        Parse and add response fields to an existing method.

        Args:
            method_name: The camelCase method name (e.g., "getLatestLedger")
            response_content: Go source code containing the response struct
            sources: Go sources of every fetched protocol file

        Raises:
            ValueError: If the content holds no response struct with a
                JSON-tagged field
        """
        response_fields = self.parse_response_fields(response_content, sources)
        if not response_fields:
            raise ValueError(f"No response fields parsed for {method_name}")
        self.methods[method_name]["response_fields"] = response_fields

    def add_response_fields_to_all_methods(self, response_files: Dict[str, str]) -> None:
        """
        Parse and add response fields to every parsed method.

        The Response Field Coverage table covers every method, so each parsed
        method needs its response file.

        Args:
            response_files: Mapping of camelCase method name to the Go source
                containing its response struct

        Raises:
            ValueError: If a parsed method has no response file (the message
                lists every such method) or a response file yields no fields
        """
        method_names = self.get_method_names()
        missing = [name for name in method_names if name not in response_files]
        if missing:
            raise ValueError(
                f"No response struct file for {len(missing)} of the "
                f"{len(method_names)} parsed RPC methods: {', '.join(missing)}"
            )

        sources = list(response_files.values())
        for method_name in method_names:
            self.add_response_fields_to_method(method_name, response_files[method_name], sources)

    def to_json(self) -> Dict[str, Any]:
        """
        Convert parsed methods to structured JSON format.

        Returns:
            Dictionary containing metadata and method definitions
        """
        return {
            "metadata": {
                "generated_at": datetime.now().isoformat(),
                "rpc_version": self.version_info["version"],
                "rpc_release_date": self.version_info["release_date"],
                "rpc_release_url": self.version_info["release_url"],
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
