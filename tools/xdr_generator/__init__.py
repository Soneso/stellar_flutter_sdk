"""
XDR Code Generator for Flutter Stellar SDK

This package provides tools to generate Dart XDR files from Stellar XDR definitions.

Features:
- Fetch XDR definitions from stellar/stellar-xdr GitHub releases
- Parse XDR syntax into an AST
- Generate Dart code matching existing patterns
- Preserve custom helper methods using marker-based approach
- Multi-layer validation

Version: 0.2.0
"""

__version__ = "0.2.0"
__author__ = "The Stellar Flutter SDK Authors"

from .error_handler import (
    XdrParseError,
    UnknownTypeError,
    CircularDependencyError,
    CustomCodeConflict,
    RemovedTypeWarning,
    GeneratorErrorHandler,
)
from .xdr_fetcher import (
    get_available_versions,
    get_latest_version,
    fetch_xdr_files,
    XdrRelease,
)
from .xdr_parser import (
    parse_xdr_content,
    parse_xdr_files,
)
from .xdr_lexer import (
    tokenize_xdr,
    XdrLexer,
)
from .xdr_ast import (
    XdrFile,
    XdrConstant,
    XdrTypedef,
    XdrEnum,
    XdrEnumValue,
    XdrStruct,
    XdrUnion,
    XdrField,
    XdrUnionCase,
)

__all__ = [
    # Error Handler
    "XdrParseError",
    "UnknownTypeError",
    "CircularDependencyError",
    "CustomCodeConflict",
    "RemovedTypeWarning",
    "GeneratorErrorHandler",
    # XDR Fetcher
    "get_available_versions",
    "get_latest_version",
    "fetch_xdr_files",
    "XdrRelease",
    # XDR Parser
    "parse_xdr_content",
    "parse_xdr_files",
    "tokenize_xdr",
    "XdrLexer",
    # XDR AST
    "XdrFile",
    "XdrConstant",
    "XdrTypedef",
    "XdrEnum",
    "XdrEnumValue",
    "XdrStruct",
    "XdrUnion",
    "XdrField",
    "XdrUnionCase",
]
