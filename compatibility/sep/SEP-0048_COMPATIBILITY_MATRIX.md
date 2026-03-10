# SEP-0048 (Contract Interface Specification) Compatibility Matrix

**Generated:** 2026-03-10 19:47:53  
**SDK Version:** 3.0.4  
**SEP Version:** 1.1.0  
**SEP Status:** Active  
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0048.md

## SEP Summary

A standard for contracts to self-describe their exported interface.

## Overall Coverage

**Total Coverage:** 100.0% (31/31 fields)

- ✅ **Implemented:** 31/31
- ❌ **Not Implemented:** 0/31

**Required Fields:** 100.0% (31/31)

**Optional Fields:** 0% (0/0)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/soroban/soroban_contract_parser.dart`
- `lib/src/soroban/contract_spec.dart`
- `lib/src/xdr/xdr_sc_spec_entry.dart`
- `lib/src/xdr/xdr_sc_spec_type_def.dart`
- `lib/src/xdr/xdr_sc_spec_type_option.dart`
- `lib/src/xdr/xdr_sc_spec_type_result.dart`
- `lib/src/xdr/xdr_sc_spec_type_vec.dart`
- `lib/src/xdr/xdr_sc_spec_type_map.dart`
- `lib/src/xdr/xdr_sc_spec_type_tuple.dart`
- `lib/src/xdr/xdr_sc_spec_type_bytes_n.dart`
- `lib/src/xdr/xdr_sc_spec_type_udt.dart`
- `lib/src/xdr/xdr_sc_env_meta_entry.dart`
- `lib/src/xdr/xdr_sc_meta_entry.dart`

### Key Classes

- **`SorobanContractParser`**: Parser for extracting metadata from Soroban contract WASM
- **`SorobanContractParserFailed`**: Exception when contract parsing fails
- **`SorobanContractInfo`**: Container for parsed contract metadata and supported SEPs
- **`ContractSpec`**: Utility for converting Dart values to XDR based on contract spec
- **`ContractSpecException`**: Exception for contract spec conversion errors
- **`NativeUnionVal`**: Represents a native union value for contract spec conversion
- **`XdrSCSpecEntry`**: XDR structure for contract spec entries
- **`XdrSCSpecTypeDef`**: XDR structure for type definitions in contract spec
- **`XdrSCSpecTypeOption`**: XDR structure for Option<T> type in contract spec
- **`XdrSCSpecTypeResult`**: XDR structure for Result<T, E> type in contract spec
- **`XdrSCSpecTypeVec`**: XDR structure for Vec<T> type in contract spec
- **`XdrSCSpecTypeMap`**: XDR structure for Map<K, V> type in contract spec
- **`XdrSCSpecTypeTuple`**: XDR structure for tuple types in contract spec
- **`XdrSCSpecTypeBytesN`**: XDR structure for fixed-size byte arrays in contract spec
- **`XdrSCSpecTypeUDT`**: XDR structure for user-defined types in contract spec
- **`XdrSCEnvMetaEntry`**: XDR structure for environment metadata entries
- **`XdrSCMetaEntry`**: XDR structure for contract metadata entries

## Implementation Details

### Parsing Contract Bytecode

The Flutter SDK provides comprehensive bytecode parsing through the `SorobanContractParser` class:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Parse contract bytecode
final contractBytes = await Util.readFile('path/to/contract.wasm');
final contractInfo = SorobanContractParser.parseContractByteCode(contractBytes);

// Access parsed data
final envVersion = contractInfo.envInterfaceVersion;
final specEntries = contractInfo.specEntries;  // List of XdrSCSpecEntry
final metaEntries = contractInfo.metaEntries;  // Map<String, String>
final supportedSeps = contractInfo.supportedSeps;  // SEP-47 integration

// Convenient categorized access (automatically populated)
final functions = contractInfo.funcs;  // List of XdrSCSpecFunctionV0
final structs = contractInfo.udtStructs;  // List of XdrSCSpecUDTStructV0
final unions = contractInfo.udtUnions;  // List of XdrSCSpecUDTUnionV0
final enums = contractInfo.udtEnums;  // List of XdrSCSpecUDTEnumV0
final errorEnums = contractInfo.udtErrorEnums;  // List of XdrSCSpecUDTErrorEnumV0
final events = contractInfo.events;  // List of XdrSCSpecEventV0
```

### Working with Contract Specifications

The `ContractSpec` class provides utilities for working with parsed specifications:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Create ContractSpec from parsed entries
final spec = ContractSpec(contractInfo.specEntries);

// Get all functions
final functions = spec.funcs();

// Get all UDT structs
final structs = spec.udtStructs();

// Get all UDT unions
final unions = spec.udtUnions();

// Get all UDT enums
final enums = spec.udtEnums();

// Get all UDT error enums
final errorEnums = spec.udtErrorEnums();

// Get all events
final events = spec.events();

// Get specific function
final func = spec.getFunc('transfer');

// Find any entry by name (function, struct, union, enum, error enum, or event)
final entry = spec.findEntry('DataKey');

// Convert native Dart arguments to XDR SCVal
final args = {
  'from': 'GABC...',
  'to': 'GDEF...',
  'amount': 1000
};
final xdrArgs = spec.funcArgsToXdrSCValues('transfer', args);
```

### Type System Support

The SDK provides complete XDR type system support with 70+ XDR classes covering:

- **Primitive types**: bool, u32, i32, u64, i64, u128, i128, u256, i256, address, bytes, string, symbol, void, timepoint, duration
- **Compound types**: vec, map, tuple, option, result, bytesN
- **User-defined types**: struct, union, enum, error enum
- **Special types**: function inputs, event parameters

### Native to XDR Conversion

The `ContractSpec` class includes production-ready type conversion:

```dart
// Supports all primitive types
spec.nativeToXdrSCVal(true, boolType);
spec.nativeToXdrSCVal(42, u32Type);
spec.nativeToXdrSCVal('Hello', stringType);

// Supports compound types
spec.nativeToXdrSCVal([1, 2, 3], vecType);
spec.nativeToXdrSCVal({'key': 'value'}, mapType);

// Supports BigInt values for u128, i128, u256, i256
spec.nativeToXdrSCVal(BigInt.parse('123456789'), u128Type);
spec.nativeToXdrSCVal('999999999999999999', u256Type);

// Supports user-defined types
spec.nativeToXdrSCVal({'name': 'Alice'}, structType);
```

## Integration with Other SEPs

### SEP-46 (Contract Meta)

SEP-48 builds on SEP-46 by parsing metadata from the `contractmetav0` custom section:

```dart
// Meta entries are automatically parsed
final metaEntries = contractInfo.metaEntries;

// Example: Get contract version
final version = metaEntries['version'];
```

### SEP-47 (Contract Interface Discovery)

SEP-48 implementation includes full SEP-47 support for discovering which SEPs a contract implements:

```dart
// Supported SEPs are automatically extracted from meta entries
final supportedSeps = contractInfo.supportedSeps;

// Example: Check if contract supports SEP-41
if (supportedSeps.contains('41')) {
  // Contract implements SEP-41 (Token Interface)
}
```

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |
|---------|----------|-------------------|-------------|-----------------|-------|
| Entry Types | 100.0% | 100.0% | 6 | 0 | 6 |
| Parsing Support | 100.0% | 100.0% | 4 | 0 | 4 |
| Type System - Compound Types | 100.0% | 100.0% | 7 | 0 | 7 |
| Type System - Primitive Types | 100.0% | 100.0% | 6 | 0 | 6 |
| Wasm Custom Section | 100.0% | 100.0% | 4 | 0 | 4 |
| XDR Support | 100.0% | 100.0% | 4 | 0 | 4 |

## Detailed Field Comparison

### Entry Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `enum_specs` | ✓ | ✅ | `specEntries` | Parse enum type specification entries (SC_SPEC_ENTRY_UDT_ENUM_V0) |
| `error_enum_specs` | ✓ | ✅ | `specEntries` | Parse error enum specification entries (SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0) |
| `event_specs` | ✓ | ✅ | `specEntries` | Parse event specification entries (SC_SPEC_ENTRY_EVENT_V0) |
| `function_specs` | ✓ | ✅ | `specEntries` | Parse function specification entries (SC_SPEC_ENTRY_FUNCTION_V0) |
| `struct_specs` | ✓ | ✅ | `specEntries` | Parse struct type specification entries (SC_SPEC_ENTRY_UDT_STRUCT_V0) |
| `union_specs` | ✓ | ✅ | `specEntries` | Parse union type specification entries (SC_SPEC_ENTRY_UDT_UNION_V0) |

### Parsing Support

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `extract_spec_entries` | ✓ | ✅ | `specEntries` | Extract and decode all specification entries |
| `parse_contract_bytecode` | ✓ | ✅ | `parseContractByteCode` | Parse contract specifications from Wasm bytecode |
| `parse_contract_meta` | ✓ | ✅ | `metaEntries` | Parse contract metadata key-value pairs |
| `parse_environment_meta` | ✓ | ✅ | `envProtocolVersion` | Parse environment metadata (interface version) |

### Type System - Compound Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `bytes_n_type` | ✓ | ✅ | `XdrSCSpecTypeBytesN` | Support for fixed-length bytes type (SC_SPEC_TYPE_BYTES_N) |
| `map_type` | ✓ | ✅ | `XdrSCSpecTypeMap` | Support for Map<K, V> type (SC_SPEC_TYPE_MAP) |
| `option_type` | ✓ | ✅ | `XdrSCSpecTypeOption` | Support for Option<T> type (SC_SPEC_TYPE_OPTION) |
| `result_type` | ✓ | ✅ | `XdrSCSpecTypeResult` | Support for Result<T, E> type (SC_SPEC_TYPE_RESULT) |
| `tuple_type` | ✓ | ✅ | `XdrSCSpecTypeTuple` | Support for tuple types (SC_SPEC_TYPE_TUPLE) |
| `user_defined_type` | ✓ | ✅ | `XdrSCSpecTypeUDT` | Support for user-defined types (SC_SPEC_TYPE_UDT) |
| `vector_type` | ✓ | ✅ | `XdrSCSpecTypeVec` | Support for Vec<T> type (SC_SPEC_TYPE_VEC) |

### Type System - Primitive Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `address_type` | ✓ | ✅ | `XdrSCSpecTypeDef` | Support for address type (SC_SPEC_TYPE_ADDRESS) |
| `boolean_type` | ✓ | ✅ | `XdrSCSpecTypeDef` | Support for boolean type (SC_SPEC_TYPE_BOOL) |
| `bytes_string_symbol` | ✓ | ✅ | `XdrSCSpecTypeDef` | Support for bytes, string, and symbol types |
| `numeric_types` | ✓ | ✅ | `XdrSCSpecTypeDef` | Support for numeric types (u32, i32, u64, i64, u128, i128, u256, i256) |
| `timepoint_duration` | ✓ | ✅ | `XdrSCSpecTypeDef` | Support for timepoint and duration types |
| `void_type` | ✓ | ✅ | `XdrSCSpecTypeDef` | Support for void type (SC_SPEC_TYPE_VOID) |

### Wasm Custom Section

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `contractenvmetav0_section` | ✓ | ✅ | `envProtocolVersion` | Support for "contractenvmetav0" Wasm custom section for environment metadata |
| `contractmetav0_section` | ✓ | ✅ | `metaEntries` | Support for "contractmetav0" Wasm custom section for contract metadata |
| `contractspecv0_section` | ✓ | ✅ | `specEntries` | Support for "contractspecv0" Wasm custom section |
| `xdr_binary_encoding` | ✓ | ✅ | `decode` | Parse XDR binary encoded specification entries |

### XDR Support

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `decode_scenvmetaentry` | ✓ | ✅ | `XdrSCEnvMetaEntry` | Decode SCEnvMetaEntry XDR structures |
| `decode_scmetaentry` | ✓ | ✅ | `XdrSCMetaEntry` | Decode SCMetaEntry XDR structures |
| `decode_scspecentry` | ✓ | ✅ | `XdrSCSpecEntry` | Decode SCSpecEntry XDR structures |
| `decode_scspectypedef` | ✓ | ✅ | `XdrSCSpecTypeDef` | Decode SCSpecTypeDef XDR structures for type definitions |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0048!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
