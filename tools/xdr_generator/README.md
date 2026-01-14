# XDR Code Generator for Flutter Stellar SDK

Tool to generate Dart XDR files from Stellar XDR definitions hosted at [stellar/stellar-xdr](https://github.com/stellar/stellar-xdr).

## Features

- Fetches XDR definitions from any stellar-xdr release (v19 - v25.0+)
- Parses all XDR constructs (typedef, enum, struct, union, const)
- Generates Dart code matching existing SDK patterns exactly
- Preserves custom helper methods using CUSTOM_CODE markers
- Preserves helper classes not in XDR spec (e.g., XdrAccountID, XdrLedgerKeyOffer)
- Handles SDK-specific class naming conventions
- Multi-layer validation (structural, compilation, test suite)
- Correctly handles `string<N>` as String type (not array)

## Requirements

- Python 3.7+
- No external dependencies (uses only Python standard library)

## Quick Start

```bash
cd /Users/chris/projects/Stellar/stellar_flutter_sdk

# List available XDR versions
python -m tools.xdr_generator --list-versions

# Generate from latest version
python -m tools.xdr_generator

# Generate from specific version
python -m tools.xdr_generator --version v25.0

# Verbose output
python -m tools.xdr_generator --version v25.0 --verbose
```

## CLI Reference

```
usage: xdr_generator [-h] [-v VERSION] [--list-versions] [--list-types]
                     [-o OUTPUT] [--verbose] [--skip-tests]
                     [--skip-validation] [--show-version]

Generate Dart XDR files from Stellar XDR definitions

options:
  -h, --help            Show help message
  -v, --version VERSION XDR release version (default: latest)
  --list-versions       List available XDR releases
  --list-types          List types that would be generated
  -o, --output OUTPUT   Output directory (default: lib/src/xdr/)
  --verbose             Show detailed progress
  --skip-tests          Skip test suite validation (faster)
  --skip-validation     Skip all validation (not recommended)
  --show-version        Show generator version
```

## GitHub Authentication

To avoid API rate limits (60 req/hour unauthenticated), set up authentication:

**Option 1: Environment Variable**
```bash
export GITHUB_TOKEN=your_token_here
```

**Option 2: GitHub CLI**
```bash
gh auth login
```

Authenticated requests get 5,000 requests/hour. Create a token at https://github.com/settings/tokens (no scopes needed for public repos).

## How It Works

### 1. Fetch XDR Definitions
Downloads `.x` files from stellar-xdr GitHub releases.

### 2. Parse XDR Syntax
Tokenizes and parses XDR into an AST supporting:
- `typedef` - Type aliases and opaque definitions
- `enum` - Enumeration types with integer values
- `struct` - Record types with fields
- `union switch` - Discriminated unions
- `const` - Named constants

### 3. Generate Dart Code
Produces Dart classes matching existing SDK patterns:
- Enums with `_internal` constructor and static const values
- Structs with private fields, getters/setters, and constructor
- Unions with discriminant and nullable variant fields
- Static `encode()` and `decode()` methods

### 4. Preserve Custom Code
Custom methods marked with `// CUSTOM_CODE_START` and `// CUSTOM_CODE_END` are preserved during regeneration:
```dart
class XdrTransactionMeta {
  // ... generated code ...

  // CUSTOM_CODE_START
  static XdrTransactionMeta fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrTransactionMeta.decode(XdrDataInputStream(bytes));
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrTransactionMeta.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }
  // CUSTOM_CODE_END
}
```

### 5. Validate Output
- Structural validation: Verifies encode/decode methods exist
- Compilation validation: Runs `dart analyze`
- Test suite: Runs existing SDK tests

## Custom Code Markers

The following files contain custom methods protected by `CUSTOM_CODE_START`/`CUSTOM_CODE_END` marker pairs:

| File | Marker Pairs | Custom Methods |
|------|--------------|----------------|
| xdr_type.dart | 1 | 1 (forAccountId) |
| xdr_account.dart | 2 | 4 (forAccountId, encodeInverted, decodeInverted, accountId getter) |
| xdr_asset.dart | 2 | 2 (fromXdrAsset converters) |
| xdr_transaction.dart | 8 | 16 (base64 helpers, factory methods) |
| xdr_contract.dart | 12 | 89 (factory methods for SCVal, SCAddress, etc.) |
| xdr_ledger.dart | 7 | 24 (factory methods, base64 helpers, getters) |

**Total: 32 marker pairs protecting 136 custom methods**

## Module Structure

```
tools/xdr_generator/
  __init__.py           # Package exports
  __main__.py           # Module entry point
  main.py               # CLI interface
  error_handler.py      # Error/warning classes
  xdr_fetcher.py        # GitHub API integration
  xdr_lexer.py          # XDR tokenizer
  xdr_parser.py         # XDR parser
  xdr_ast.py            # AST node definitions
  type_mapping.py       # XDR-to-Dart type mappings
  file_mapping.py       # Type-to-file assignments
  dependency_resolver.py # Cross-file dependencies
  dart_generator.py     # Dart code generation
  dart_analyzer.py      # Existing file analysis
  dart_merger.py        # Code merging
  validator.py          # Output validation
```

## Type Mappings

### Primitive Types
| XDR | Dart |
|-----|------|
| int32 | XdrInt32 |
| uint32 | XdrUint32 |
| int64 | XdrInt64 |
| uint64 | XdrUint64 |
| bool | bool |
| string | String |
| opaque | Uint8List |

### Special Wrapper Types
| XDR Context | Dart Wrapper |
|-------------|--------------|
| Hash | XdrHash |
| uint256 | XdrUint256 |
| Signature | XdrSignature |
| SignatureHint | XdrSignatureHint |
| Thresholds | XdrThresholds |
| String32 | XdrString32 |
| String64 | XdrString64 |
| Value | XdrValue |
| SequenceNumber | XdrBigInt64 |
| TimePoint | XdrBigInt64 |
| Duration | XdrBigInt64 |

## Error Handling

- `XdrParseError` - Fatal XDR parsing error
- `UnknownTypeError` - Reference to undefined type
- `CircularDependencyError` - Circular import (fatal)
- `CustomCodeConflict` - Custom code conflicts with generated
- `RemovedTypeWarning` - Type removed in new XDR version

## Testing

Run the end-to-end test:
```bash
python tools/xdr_generator/test_end_to_end.py
```

Expected output: "Overall: 7/7 phases passed"

## Updating XDR When New Protocol Version Released

1. Check available versions:
   ```bash
   python -m tools.xdr_generator --list-versions
   ```

2. Generate from new version:
   ```bash
   python -m tools.xdr_generator --version vXX.0 --verbose
   ```

3. Review changes:
   ```bash
   git diff lib/src/xdr/
   ```

4. Run tests:
   ```bash
   dart test
   ```

5. Commit if tests pass.

## Version

Generator version: 0.2.0

Supports stellar-xdr versions: v19 through v25.0+
