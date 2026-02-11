// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import '../xdr/xdr_contract.dart';
import '../util.dart';

/// Utility class for working with Soroban contract specifications.
///
/// ContractSpec provides type-safe conversion between native Dart values and Soroban's
/// XDR value types (XdrSCVal). It uses contract specification entries to ensure correct
/// type mapping and validation.
///
/// Contract specifications define:
/// - Function signatures with parameter types and return types
/// - User-defined types (structs, unions, enums)
/// - Event schemas
///
/// Use this class to:
/// - Convert function arguments from Dart types to XdrSCVal
/// - Validate arguments match the contract's expected types
/// - Work with complex types (structs, unions, enums) defined in contracts
/// - Convert native values when you know the target type
///
/// The SDK automatically uses ContractSpec when you work with SorobanClient.
/// For advanced use cases, you can use it directly for fine-grained type conversion.
///
/// Example - Basic usage with SorobanClient:
/// ```dart
/// // SorobanClient internally uses ContractSpec
/// final client = await SorobanClient.forClientOptions(options: options);
///
/// // Use convenient conversion method
/// final args = client.funcArgsToXdrSCValues('transfer', {
///   'from': 'GABC...',
///   'to': 'GDEF...',
///   'amount': 1000,
/// });
///
/// final result = await client.invokeMethod(name: 'transfer', args: args);
/// ```
///
/// Example - Direct usage for custom conversion:
/// ```dart
/// final spec = ContractSpec(contractInfo.specEntries);
///
/// // Convert a struct
/// final structValue = spec.nativeToXdrSCVal(
///   {'field1': 'value1', 'field2': 42},
///   structTypeDef,
/// );
///
/// // Convert an enum value
/// final enumValue = spec.nativeToXdrSCVal('SUCCESS', enumTypeDef);
///
/// // Convert a union (use NativeUnionVal)
/// final unionValue = spec.nativeToXdrSCVal(
///   NativeUnionVal.tupleCase('Data', ['value1', 'value2']),
///   unionTypeDef,
/// );
/// ```
///
/// Supported type conversions:
/// - Basic types: bool, integers (u32, i32, u64, i64, u128, i128, u256, i256)
/// - Time types: timepoint, duration
/// - Data types: bytes, bytesN, string, symbol
/// - Address types: account, contract addresses
/// - Collections: vec (lists), map (key-value pairs), tuple
/// - User-defined types: struct, union, enum, error enum
/// - Special types: option (nullable), result (success/error)
///
/// See also:
/// - [SorobanClient] for high-level contract interaction
/// - [SorobanClient.funcArgsToXdrSCValues] for convenient argument conversion
/// - [SorobanServer] for low-level RPC operations
/// - [NativeUnionVal] for union type values
/// - [ContractSpecException] for type conversion errors
class ContractSpec {
  final List<XdrSCSpecEntry> entries;

  /// Maximum signed 64-bit integer value (web-safe).
  static final BigInt _maxInt64 = BigInt.parse('7FFFFFFFFFFFFFFF', radix: 16);

  /// Minimum signed 64-bit integer value (web-safe).
  static final BigInt _minInt64 = -BigInt.parse('8000000000000000', radix: 16);

  /// Creates a ContractSpec from a list of spec entries.
  const ContractSpec(this.entries);

  /// Returns all function specifications from the contract spec.
  List<XdrSCSpecFunctionV0> funcs() {
    final functions = <XdrSCSpecFunctionV0>[];
    for (final entry in entries) {
      if (entry.discriminant == XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0) {
        final func = entry.functionV0;
        if (func != null) {
          functions.add(func);
        }
      }
    }
    return functions;
  }

  /// Returns all UDT struct specifications from the contract spec.
  List<XdrSCSpecUDTStructV0> udtStructs() {
    final structs = <XdrSCSpecUDTStructV0>[];
    for (final entry in entries) {
      if (entry.discriminant ==
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0) {
        final struct = entry.udtStructV0;
        if (struct != null) {
          structs.add(struct);
        }
      }
    }
    return structs;
  }

  /// Returns all UDT union specifications from the contract spec.
  List<XdrSCSpecUDTUnionV0> udtUnions() {
    final unions = <XdrSCSpecUDTUnionV0>[];
    for (final entry in entries) {
      if (entry.discriminant == XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0) {
        final union = entry.udtUnionV0;
        if (union != null) {
          unions.add(union);
        }
      }
    }
    return unions;
  }

  /// Returns all UDT enum specifications from the contract spec.
  List<XdrSCSpecUDTEnumV0> udtEnums() {
    final enums = <XdrSCSpecUDTEnumV0>[];
    for (final entry in entries) {
      if (entry.discriminant == XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0) {
        final enumEntry = entry.udtEnumV0;
        if (enumEntry != null) {
          enums.add(enumEntry);
        }
      }
    }
    return enums;
  }

  /// Returns all UDT error enum specifications from the contract spec.
  List<XdrSCSpecUDTErrorEnumV0> udtErrorEnums() {
    final errorEnums = <XdrSCSpecUDTErrorEnumV0>[];
    for (final entry in entries) {
      if (entry.discriminant ==
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0) {
        final errorEnum = entry.udtErrorEnumV0;
        if (errorEnum != null) {
          errorEnums.add(errorEnum);
        }
      }
    }
    return errorEnums;
  }

  /// Returns all event specifications from the contract spec.
  List<XdrSCSpecEventV0> events() {
    final events = <XdrSCSpecEventV0>[];
    for (final entry in entries) {
      if (entry.discriminant == XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0) {
        final event = entry.eventV0;
        if (event != null) {
          events.add(event);
        }
      }
    }
    return events;
  }

  /// Finds a specific function specification by name.
  /// Returns null if the function is not found.
  XdrSCSpecFunctionV0? getFunc(String name) {
    for (final func in funcs()) {
      if (func.name == name) {
        return func;
      }
    }
    return null;
  }

  /// Finds any spec entry by name.
  /// Searches across functions, structs, unions, enums, and error enums.
  /// Returns null if the entry is not found.
  XdrSCSpecEntry? findEntry(String name) {
    for (final entry in entries) {
      switch (entry.discriminant) {
        case XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0:
          final func = entry.functionV0;
          if (func != null && func.name == name) {
            return entry;
          }
          break;
        case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0:
          final struct = entry.udtStructV0;
          if (struct != null && struct.name == name) {
            return entry;
          }
          break;
        case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0:
          final union = entry.udtUnionV0;
          if (union != null && union.name == name) {
            return entry;
          }
          break;
        case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0:
          final enumEntry = entry.udtEnumV0;
          if (enumEntry != null && enumEntry.name == name) {
            return entry;
          }
          break;
        case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0:
          final errorEnum = entry.udtErrorEnumV0;
          if (errorEnum != null && errorEnum.name == name) {
            return entry;
          }
          break;
        case XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0:
          final event = entry.eventV0;
          if (event != null && event.name == name) {
            return entry;
          }
          break;
      }
    }
    return null;
  }

  /// Converts function arguments to XdrSCVal objects based on the function specification.
  ///
  /// [name] The function name
  /// [args] Map of argument names to values
  ///
  /// Returns a list of XdrSCVal objects in the correct order for the function.
  /// Throws ContractSpecException if the function is not found or required arguments are missing.
  List<XdrSCVal> funcArgsToXdrSCValues(String name, Map<String, dynamic> args) {
    final func = getFunc(name);
    if (func == null) {
      throw ContractSpecException.functionNotFound(name);
    }

    final scValues = <XdrSCVal>[];
    for (final input in func.inputs) {
      final argName = input.name;
      if (!args.containsKey(argName)) {
        throw ContractSpecException.argumentNotFound(argName,
            functionName: name);
      }

      final argValue = args[argName];
      final scValue = nativeToXdrSCVal(argValue, input.type);
      scValues.add(scValue);
    }

    return scValues;
  }

  /// Converts a native Dart value to an XdrSCVal based on the type specification.
  ///
  /// This is the core conversion method that handles all type mappings from Dart
  /// native types to Stellar XDR values.
  ///
  /// [val] The native Dart value to convert
  /// [ty] The target type specification
  ///
  /// Returns the converted XdrSCVal.
  /// Throws ContractSpecException for invalid types or conversion failures.
  XdrSCVal nativeToXdrSCVal(dynamic val, XdrSCSpecTypeDef ty) {
    // Handle null values
    if (val == null) {
      return XdrSCVal.forVoid();
    }

    // If already an XdrSCVal, return as-is
    if (val is XdrSCVal) {
      return val;
    }

    switch (ty.discriminant) {
      // Basic value types
      case XdrSCSpecType.SC_SPEC_TYPE_VAL:
      case XdrSCSpecType.SC_SPEC_TYPE_BOOL:
      case XdrSCSpecType.SC_SPEC_TYPE_VOID:
      case XdrSCSpecType.SC_SPEC_TYPE_ERROR:
      case XdrSCSpecType.SC_SPEC_TYPE_U32:
      case XdrSCSpecType.SC_SPEC_TYPE_I32:
      case XdrSCSpecType.SC_SPEC_TYPE_U64:
      case XdrSCSpecType.SC_SPEC_TYPE_I64:
      case XdrSCSpecType.SC_SPEC_TYPE_TIMEPOINT:
      case XdrSCSpecType.SC_SPEC_TYPE_DURATION:
      case XdrSCSpecType.SC_SPEC_TYPE_U128:
      case XdrSCSpecType.SC_SPEC_TYPE_I128:
      case XdrSCSpecType.SC_SPEC_TYPE_U256:
      case XdrSCSpecType.SC_SPEC_TYPE_I256:
      case XdrSCSpecType.SC_SPEC_TYPE_BYTES:
      case XdrSCSpecType.SC_SPEC_TYPE_STRING:
      case XdrSCSpecType.SC_SPEC_TYPE_SYMBOL:
      case XdrSCSpecType.SC_SPEC_TYPE_ADDRESS:
      case XdrSCSpecType.SC_SPEC_TYPE_MUXED_ADDRESS:
        return _handleValueType(val, ty);
      // Complex types
      case XdrSCSpecType.SC_SPEC_TYPE_OPTION:
        return _handleOptionType(val, ty);
      case XdrSCSpecType.SC_SPEC_TYPE_RESULT:
        return _handleResultType(val, ty);
      case XdrSCSpecType.SC_SPEC_TYPE_VEC:
        return _handleVecType(val, ty);
      case XdrSCSpecType.SC_SPEC_TYPE_MAP:
        return _handleMapType(val, ty);
      case XdrSCSpecType.SC_SPEC_TYPE_TUPLE:
        return _handleTupleType(val, ty);
      case XdrSCSpecType.SC_SPEC_TYPE_BYTES_N:
        return _handleBytesNType(val, ty);
      case XdrSCSpecType.SC_SPEC_TYPE_UDT:
        return _handleUDTType(val, ty);
      default:
        throw ContractSpecException.invalidType(
            'Unsupported type: ${ty.discriminant}');
    }
  }

  /// Handles basic value types (bool, numbers, strings, addresses, etc.)
  XdrSCVal _handleValueType(dynamic val, XdrSCSpecTypeDef ty) {
    switch (ty.discriminant) {
      case XdrSCSpecType.SC_SPEC_TYPE_VAL:
        return _inferType(val);
      case XdrSCSpecType.SC_SPEC_TYPE_VOID:
        return XdrSCVal.forVoid();
      case XdrSCSpecType.SC_SPEC_TYPE_BOOL:
        if (val is! bool) {
          throw ContractSpecException.invalidType(
              'Expected bool, got ${val.runtimeType}');
        }
        return XdrSCVal.forBool(val);
      case XdrSCSpecType.SC_SPEC_TYPE_U32:
        final intVal = _parseInteger(val, 'u32');
        if (intVal < 0 || intVal > 0xFFFFFFFF) {
          throw ContractSpecException.invalidType(
              'Value $intVal out of range for u32');
        }
        return XdrSCVal.forU32(intVal);
      case XdrSCSpecType.SC_SPEC_TYPE_I32:
        final intVal = _parseInteger(val, 'i32');
        if (intVal < -0x80000000 || intVal > 0x7FFFFFFF) {
          throw ContractSpecException.invalidType(
              'Value $intVal out of range for i32');
        }
        return XdrSCVal.forI32(intVal);
      case XdrSCSpecType.SC_SPEC_TYPE_U64:
        final intVal = _parseInteger(val, 'u64');
        if (intVal < 0) {
          throw ContractSpecException.invalidType(
              'Value $intVal out of range for u64');
        }
        return XdrSCVal.forU64(BigInt.from(intVal));
      case XdrSCSpecType.SC_SPEC_TYPE_I64:
        final intVal = _parseInteger(val, 'i64');
        return XdrSCVal.forI64(BigInt.from(intVal));
      case XdrSCSpecType.SC_SPEC_TYPE_TIMEPOINT:
        final intVal = _parseInteger(val, 'timepoint');
        if (intVal < 0) {
          throw ContractSpecException.invalidType(
              'Value $intVal out of range for timepoint');
        }
        return XdrSCVal.forTimepoint(BigInt.from(intVal));
      case XdrSCSpecType.SC_SPEC_TYPE_DURATION:
        final intVal = _parseInteger(val, 'duration');
        if (intVal < 0) {
          throw ContractSpecException.invalidType(
              'Value $intVal out of range for duration');
        }
        return XdrSCVal.forDuration(BigInt.from(intVal));
      case XdrSCSpecType.SC_SPEC_TYPE_U128:
        return _handleU128Type(val);
      case XdrSCSpecType.SC_SPEC_TYPE_I128:
        return _handleI128Type(val);
      case XdrSCSpecType.SC_SPEC_TYPE_U256:
        return _handleU256Type(val);
      case XdrSCSpecType.SC_SPEC_TYPE_I256:
        return _handleI256Type(val);
      case XdrSCSpecType.SC_SPEC_TYPE_BYTES:
        return _handleBytesType(val);
      case XdrSCSpecType.SC_SPEC_TYPE_STRING:
        if (val is! String) {
          throw ContractSpecException.invalidType(
              'Expected String, got ${val.runtimeType}');
        }
        return XdrSCVal.forString(val);
      case XdrSCSpecType.SC_SPEC_TYPE_SYMBOL:
        if (val is! String) {
          throw ContractSpecException.invalidType(
              'Expected String, got ${val.runtimeType}');
        }
        return XdrSCVal.forSymbol(val);
      case XdrSCSpecType.SC_SPEC_TYPE_ADDRESS:
        return _handleAddressType(val);
      default:
        throw ContractSpecException.invalidType(
            'Unsupported value type: ${ty.discriminant}');
    }
  }

  /// Infer XdrSCVal type from native Dart value when spec type is SC_SPEC_TYPE_VAL
  XdrSCVal _inferType(dynamic val) {
    if (val is bool) {
      return XdrSCVal.forBool(val);
    } else if (val is int) {
      if (val >= 0 && val <= 0xFFFFFFFF) {
        return XdrSCVal.forU32(val);
      } else if (val >= -0x80000000 && val < 0) {
        return XdrSCVal.forI32(val);
      } else {
        return XdrSCVal.forI64(BigInt.from(val));
      }
    } else if (val is BigInt) {
      return XdrSCVal.forI128BigInt(val);
    } else if (val is String) {
      return XdrSCVal.forString(val);
    } else if (val is Uint8List) {
      return XdrSCVal.forBytes(val);
    } else if (val is List) {
      final vec = val.map((e) => _inferType(e)).toList();
      return XdrSCVal.forVec(vec);
    } else if (val is Map) {
      final entries = val.entries.map((e) {
        return XdrSCMapEntry(_inferType(e.key), _inferType(e.value));
      }).toList();
      return XdrSCVal.forMap(entries);
    }
    throw ContractSpecException.invalidType(
        'Cannot infer type for value: ${val.runtimeType}');
  }

  /// Parse integer from various input types
  int _parseInteger(dynamic val, String typeName) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) {
      final parsed = int.tryParse(val);
      if (parsed == null) {
        throw ContractSpecException.invalidType(
            'Cannot parse "$val" as integer for $typeName');
      }
      return parsed;
    }
    throw ContractSpecException.invalidType(
        'Expected int, got ${val.runtimeType} for $typeName');
  }

  /// Handle 128-bit unsigned integer conversion
  XdrSCVal _handleU128Type(dynamic val) {
    if (val is XdrUInt128Parts) {
      return XdrSCVal.forU128(val);
    }

    if (val is BigInt) {
      if (val < BigInt.zero) {
        throw ContractSpecException.invalidType(
            'Value $val out of range for u128 (negative)');
      }
      return XdrSCVal.forU128BigInt(val);
    }

    // For small integers, convert to 128-bit parts
    final intVal = _parseInteger(val, 'u128');
    if (intVal < 0) {
      throw ContractSpecException.invalidType(
          'Value $intVal out of range for u128');
    }

    // Simple conversion for values that fit in int64
    if (BigInt.from(intVal) <= _maxInt64) {
      return XdrSCVal.forU128Parts(BigInt.zero, BigInt.from(intVal));
    }

    throw ContractSpecException.conversionFailed(
        'Large u128 values require XdrUInt128Parts or BigInt object');
  }

  /// Handle 128-bit signed integer conversion
  XdrSCVal _handleI128Type(dynamic val) {
    if (val is XdrInt128Parts) {
      return XdrSCVal.forI128(val);
    }

    if (val is BigInt) {
      return XdrSCVal.forI128BigInt(val);
    }

    // For small integers, convert to 128-bit parts
    final intVal = _parseInteger(val, 'i128');

    // Simple conversion for values that fit in int64
    if (BigInt.from(intVal) >= _minInt64 && BigInt.from(intVal) <= _maxInt64) {
      final hi = intVal < 0 ? BigInt.from(-1) : BigInt.zero; // Sign extension
      return XdrSCVal.forI128Parts(hi, BigInt.from(intVal));
    }

    throw ContractSpecException.conversionFailed(
        'Large i128 values require XdrInt128Parts or BigInt object');
  }

  /// Handle 256-bit unsigned integer conversion
  XdrSCVal _handleU256Type(dynamic val) {
    if (val is XdrUInt256Parts) {
      return XdrSCVal.forU256(val);
    }

    if (val is BigInt) {
      if (val < BigInt.zero) {
        throw ContractSpecException.invalidType(
            'Value $val out of range for u256 (negative)');
      }
      return XdrSCVal.forU256BigInt(val);
    }

    // For small integers, convert to BigInt then to 256-bit
    final intVal = _parseInteger(val, 'u256');
    if (intVal < 0) {
      throw ContractSpecException.invalidType(
          'Value $intVal out of range for u256');
    }

    return XdrSCVal.forU256BigInt(BigInt.from(intVal));
  }

  /// Handle 256-bit signed integer conversion
  XdrSCVal _handleI256Type(dynamic val) {
    if (val is XdrInt256Parts) {
      return XdrSCVal.forI256(val);
    }

    if (val is BigInt) {
      return XdrSCVal.forI256BigInt(val);
    }

    // For small integers, convert to BigInt then to 256-bit
    final intVal = _parseInteger(val, 'i256');
    return XdrSCVal.forI256BigInt(BigInt.from(intVal));
  }

  /// Handle bytes type conversion
  XdrSCVal _handleBytesType(dynamic val) {
    if (val is Uint8List) {
      return XdrSCVal.forBytes(val);
    }
    if (val is List<int>) {
      return XdrSCVal.forBytes(Uint8List.fromList(val));
    }
    if (val is String) {
      // Assume hex string
      try {
        final bytes = Util.hexToBytes(val);
        return XdrSCVal.forBytes(bytes);
      } catch (e) {
        throw ContractSpecException.conversionFailed(
            'Cannot convert string "$val" to bytes: $e');
      }
    }

    throw ContractSpecException.invalidType(
        'Expected Uint8List, List<int>, or hex String, got ${val.runtimeType}');
  }

  /// Handle address type conversion
  XdrSCVal _handleAddressType(dynamic val) {
    if (val is String) {
      // Detect address type by prefix
      if (val.startsWith('C')) {
        // Contract address
        return XdrSCVal.forContractAddress(val);
      } else if (val.startsWith('G')) {
        // Account address
        return XdrSCVal.forAccountAddress(val);
      } else {
        throw ContractSpecException.invalidType('Invalid address format: $val');
      }
    }

    throw ContractSpecException.invalidType(
        'Expected String address, got ${val.runtimeType}');
  }

  /// Handle vector value type (for generic SCV_VEC)
  XdrSCVal _handleVecValue(dynamic val) {
    if (val is! List) {
      throw ContractSpecException.invalidType(
          'Expected List, got ${val.runtimeType}');
    }

    final scValues = <XdrSCVal>[];
    for (final item in val) {
      // For generic vectors, we don't know the element type
      // So we'll try to infer it from the value
      scValues.add(_inferAndConvert(item));
    }

    return XdrSCVal.forVec(scValues);
  }

  /// Handle map value type (for generic SCV_MAP)
  XdrSCVal _handleMapValue(dynamic val) {
    if (val is! Map) {
      throw ContractSpecException.invalidType(
          'Expected Map, got ${val.runtimeType}');
    }

    final entries = <XdrSCMapEntry>[];
    for (final entry in val.entries) {
      final keyVal = _inferAndConvert(entry.key);
      final valueVal = _inferAndConvert(entry.value);
      entries.add(XdrSCMapEntry(keyVal, valueVal));
    }

    return XdrSCVal.forMap(entries);
  }

  /// Infer type and convert value when we don't have type information
  XdrSCVal _inferAndConvert(dynamic val) {
    if (val == null) return XdrSCVal.forVoid();
    if (val is XdrSCVal) return val;
    if (val is bool) return XdrSCVal.forBool(val);
    if (val is int) {
      // Choose appropriate integer type based on value
      if (val >= 0 && val <= 0xFFFFFFFF) {
        return XdrSCVal.forU32(val);
      } else if (val >= -0x80000000 && val <= 0x7FFFFFFF) {
        return XdrSCVal.forI32(val);
      } else {
        return XdrSCVal.forI64(BigInt.from(val));
      }
    }
    if (val is String) return XdrSCVal.forString(val);
    if (val is List) return _handleVecValue(val);
    if (val is Map) return _handleMapValue(val);

    throw ContractSpecException.invalidType(
        'Cannot infer type for ${val.runtimeType}');
  }

  /// Handle option type (nullable values)
  XdrSCVal _handleOptionType(dynamic val, XdrSCSpecTypeDef ty) {
    final optionType = ty.option;
    if (optionType == null) {
      throw ContractSpecException.invalidType('Option type is null');
    }

    if (val == null) {
      return XdrSCVal.forVoid();
    }

    return nativeToXdrSCVal(val, optionType.valueType);
  }

  /// Handle result type (success/error union)
  ///
  /// Current limitation: Result type conversion is NOT YET IMPLEMENTED.
  /// This method will throw a ContractSpecException when called.
  ///
  /// Result types represent success/error unions in Soroban contracts.
  /// Future implementation will handle both success and error variants.
  ///
  /// Throws: [ContractSpecException] indicating unimplemented functionality.
  XdrSCVal _handleResultType(dynamic val, XdrSCSpecTypeDef ty) {
    final resultType = ty.result;
    if (resultType == null) {
      throw ContractSpecException.invalidType('Result type is null');
    }

    // Result types are handled as unions in practice
    throw ContractSpecException.conversionFailed(
        'Result type conversion not yet implemented');
  }

  /// Handle vector type
  XdrSCVal _handleVecType(dynamic val, XdrSCSpecTypeDef ty) {
    if (val is! List) {
      throw ContractSpecException.invalidType(
          'Expected List, got ${val.runtimeType}');
    }

    final vecType = ty.vec;
    if (vecType == null) {
      throw ContractSpecException.invalidType('Vec type is null');
    }

    final scValues = <XdrSCVal>[];
    for (final item in val) {
      scValues.add(nativeToXdrSCVal(item, vecType.elementType));
    }

    return XdrSCVal.forVec(scValues);
  }

  /// Handle map type
  XdrSCVal _handleMapType(dynamic val, XdrSCSpecTypeDef ty) {
    if (val is! Map) {
      throw ContractSpecException.invalidType(
          'Expected Map, got ${val.runtimeType}');
    }

    final mapType = ty.map;
    if (mapType == null) {
      throw ContractSpecException.invalidType('Map type is null');
    }

    final entries = <XdrSCMapEntry>[];
    for (final entry in val.entries) {
      final keyVal = nativeToXdrSCVal(entry.key, mapType.keyType);
      final valueVal = nativeToXdrSCVal(entry.value, mapType.valueType);
      entries.add(XdrSCMapEntry(keyVal, valueVal));
    }

    return XdrSCVal.forMap(entries);
  }

  /// Handle tuple type
  XdrSCVal _handleTupleType(dynamic val, XdrSCSpecTypeDef ty) {
    if (val is! List) {
      throw ContractSpecException.invalidType(
          'Expected List, got ${val.runtimeType}');
    }

    final tupleType = ty.tuple;
    if (tupleType == null) {
      throw ContractSpecException.invalidType('Tuple type is null');
    }

    if (val.length != tupleType.valueTypes.length) {
      throw ContractSpecException.invalidType(
          'Tuple length mismatch: expected ${tupleType.valueTypes.length}, got ${val.length}');
    }

    final scValues = <XdrSCVal>[];
    for (int i = 0; i < val.length; i++) {
      scValues.add(nativeToXdrSCVal(val[i], tupleType.valueTypes[i]));
    }

    return XdrSCVal.forVec(scValues);
  }

  /// Handle bytesN type (fixed-length bytes)
  XdrSCVal _handleBytesNType(dynamic val, XdrSCSpecTypeDef ty) {
    final bytesNType = ty.bytesN;
    if (bytesNType == null) {
      throw ContractSpecException.invalidType('BytesN type is null');
    }

    Uint8List bytes;
    if (val is Uint8List) {
      bytes = val;
    } else if (val is List<int>) {
      bytes = Uint8List.fromList(val);
    } else if (val is String) {
      try {
        bytes = Util.hexToBytes(val);
      } catch (e) {
        throw ContractSpecException.conversionFailed(
            'Cannot convert string "$val" to bytes: $e');
      }
    } else {
      throw ContractSpecException.invalidType(
          'Expected Uint8List, List<int>, or hex String, got ${val.runtimeType}');
    }

    if (bytes.length != bytesNType.n.uint32) {
      throw ContractSpecException.invalidType(
          'BytesN length mismatch: expected ${bytesNType.n}, got ${bytes.length}');
    }

    return XdrSCVal.forBytes(bytes);
  }

  /// Handle user-defined type (struct, union, enum)
  XdrSCVal _handleUDTType(dynamic val, XdrSCSpecTypeDef ty) {
    final udtType = ty.udt;
    if (udtType == null) {
      throw ContractSpecException.invalidType('UDT type is null');
    }

    final entry = findEntry(udtType.name);
    if (entry == null) {
      throw ContractSpecException.entryNotFound(udtType.name);
    }

    switch (entry.discriminant) {
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0:
        return _handleStructType(val, entry.udtStructV0!);
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0:
        return _handleUnionType(val, entry.udtUnionV0!);
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0:
        return _handleEnumType(val, entry.udtEnumV0!);
      default:
        throw ContractSpecException.invalidType(
            'Unsupported UDT type: ${entry.discriminant}');
    }
  }

  /// Handle struct type conversion
  XdrSCVal _handleStructType(dynamic val, XdrSCSpecUDTStructV0 structDef) {
    if (val is! Map<String, dynamic>) {
      throw ContractSpecException.invalidType(
          'Expected Map<String, dynamic> for struct ${structDef.name}, got ${val.runtimeType}');
    }

    // Determine if this should be a map or vector based on field names
    final useMap =
        structDef.fields.any((field) => !_isNumericString(field.name));

    if (useMap) {
      // Use map representation
      final entries = <XdrSCMapEntry>[];
      for (final field in structDef.fields) {
        if (!val.containsKey(field.name)) {
          throw ContractSpecException.argumentNotFound(field.name);
        }
        final keyVal = XdrSCVal.forSymbol(field.name);
        final valueVal = nativeToXdrSCVal(val[field.name], field.type);
        entries.add(XdrSCMapEntry(keyVal, valueVal));
      }
      return XdrSCVal.forMap(entries);
    } else {
      // Use vector representation (all fields are numeric)
      final scValues = <XdrSCVal>[];
      final sortedFields = structDef.fields.toList()
        ..sort((a, b) => int.parse(a.name).compareTo(int.parse(b.name)));

      for (final field in sortedFields) {
        if (!val.containsKey(field.name)) {
          throw ContractSpecException.argumentNotFound(field.name);
        }
        scValues.add(nativeToXdrSCVal(val[field.name], field.type));
      }
      return XdrSCVal.forVec(scValues);
    }
  }

  /// Handle union type conversion
  XdrSCVal _handleUnionType(dynamic val, XdrSCSpecUDTUnionV0 unionDef) {
    if (val is! NativeUnionVal) {
      throw ContractSpecException.invalidType(
          'Expected NativeUnionVal for union ${unionDef.name}, got ${val.runtimeType}');
    }

    // Find the matching union case
    XdrSCSpecUDTUnionCaseV0? matchingCase;
    for (final unionCase in unionDef.cases) {
      String? caseName;

      // Get case name based on case type
      switch (unionCase.discriminant) {
        case XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0:
          caseName = unionCase.voidCase?.name;
          break;
        case XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0:
          caseName = unionCase.tupleCase?.name;
          break;
      }

      if (caseName == val.tag) {
        matchingCase = unionCase;
        break;
      }
    }

    if (matchingCase == null) {
      throw ContractSpecException.invalidEnumValue(
          'Unknown union case "${val.tag}" for union ${unionDef.name}');
    }

    final scValues = <XdrSCVal>[];

    // Add the tag as a symbol
    scValues.add(XdrSCVal.forSymbol(val.tag));

    // Handle the case value
    switch (matchingCase.discriminant) {
      case XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0:
        // Void case - just the tag
        break;
      case XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0:
        final tupleCase = matchingCase.tupleCase;
        if (tupleCase == null) {
          throw ContractSpecException.invalidType(
              'Tuple case is null for union ${unionDef.name}');
        }

        if (val.values == null || val.values!.length != tupleCase.type.length) {
          throw ContractSpecException.invalidType(
              'Union case "${val.tag}" expects ${tupleCase.type.length} values, got ${val.values?.length ?? 0}');
        }

        for (int i = 0; i < val.values!.length; i++) {
          scValues.add(nativeToXdrSCVal(val.values![i], tupleCase.type[i]));
        }
        break;
    }

    return XdrSCVal.forVec(scValues);
  }

  /// Handle enum type conversion
  XdrSCVal _handleEnumType(dynamic val, XdrSCSpecUDTEnumV0 enumDef) {
    int? enumValue;

    if (val is int) {
      enumValue = val;
    } else if (val is String) {
      // Find enum case by name
      for (int i = 0; i < enumDef.cases.length; i++) {
        if (enumDef.cases[i].name == val) {
          enumValue = enumDef.cases[i].value.uint32;
          break;
        }
      }
      if (enumValue == null) {
        throw ContractSpecException.invalidEnumValue(
            'Unknown enum case "$val" for enum ${enumDef.name}');
      }
    } else {
      throw ContractSpecException.invalidType(
          'Expected int or String for enum ${enumDef.name}, got ${val.runtimeType}');
    }

    // Validate enum value
    final validValues = enumDef.cases.map((c) => c.value.uint32).toSet();
    if (!validValues.contains(enumValue)) {
      throw ContractSpecException.invalidEnumValue(
          'Invalid enum value $enumValue for enum ${enumDef.name}');
    }

    return XdrSCVal.forU32(enumValue);
  }

  /// Check if a string represents a numeric value
  bool _isNumericString(String str) {
    return int.tryParse(str) != null;
  }
}

/// Exception thrown when ContractSpec operations fail.
class ContractSpecException implements Exception {
  final String message;
  final String? functionName;
  final String? argumentName;
  final String? entryName;

  const ContractSpecException(
    this.message, {
    this.functionName,
    this.argumentName,
    this.entryName,
  });

  /// Returns a string representation of this instance for debugging.
  @override
  String toString() {
    var result = 'ContractSpecException: $message';
    if (functionName != null) {
      result += ' (function: $functionName)';
    }
    if (argumentName != null) {
      result += ' (argument: $argumentName)';
    }
    if (entryName != null) {
      result += ' (entry: $entryName)';
    }
    return result;
  }

  /// Exception for when a function is not found in the contract spec.
  factory ContractSpecException.functionNotFound(String name) {
    return ContractSpecException(
      'Function not found: $name',
      functionName: name,
    );
  }

  /// Exception for when a required argument is not provided.
  factory ContractSpecException.argumentNotFound(String name,
      {String? functionName}) {
    return ContractSpecException(
      'Required argument not found: $name',
      argumentName: name,
      functionName: functionName,
    );
  }

  /// Exception for when a spec entry is not found.
  factory ContractSpecException.entryNotFound(String name) {
    return ContractSpecException(
      'Entry not found: $name',
      entryName: name,
    );
  }

  /// Exception for invalid type conversion.
  factory ContractSpecException.invalidType(String message) {
    return ContractSpecException('Invalid type: $message');
  }

  /// Exception for conversion failures.
  factory ContractSpecException.conversionFailed(String message) {
    return ContractSpecException('Conversion failed: $message');
  }

  /// Exception for invalid enum values.
  factory ContractSpecException.invalidEnumValue(String message) {
    return ContractSpecException('Invalid enum value: $message');
  }
}

/// Represents a union value for Soroban contract specifications.
/// Used when passing union type values to contract functions.
///
/// Union types in Stellar contracts can have two forms:
/// 1. Void case - just a tag name (e.g., "Success", "Error")
/// 2. Tuple case - a tag name with associated values (e.g., "Data" with values `["field1", "field2"]`)
class NativeUnionVal {
  /// The union case name/tag
  final String tag;

  /// Optional values for tuple cases. Null for void cases.
  final List<dynamic>? values;

  /// Creates a void union case (no associated values)
  const NativeUnionVal.voidCase(this.tag) : values = null;

  /// Creates a tuple union case with associated values
  const NativeUnionVal.tupleCase(this.tag, this.values);

  /// Creates a union value with the specified tag and optional values
  const NativeUnionVal(this.tag, {this.values});

  /// Returns true if this is a void case (no associated values)
  bool get isVoidCase => values == null;

  /// Returns true if this is a tuple case (has associated values)
  bool get isTupleCase => values != null;

  /// Compares this instance to another for equality.
  ///
  /// Returns `true` if [other] is of the same type and all fields are equal, `false` otherwise.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NativeUnionVal) return false;

    return tag == other.tag && _listEquals(values, other.values);
  }

  /// Returns the hash code for this instance based on its fields.
  @override
  int get hashCode =>
      Object.hash(tag, values == null ? null : Object.hashAll(values!));

  /// Returns a string representation of this instance for debugging.
  @override
  String toString() {
    if (isVoidCase) {
      return 'NativeUnionVal.voidCase($tag)';
    } else {
      return 'NativeUnionVal.tupleCase($tag, $values)';
    }
  }

  /// Helper method to compare lists for equality
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
