// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/xdr/xdr_contract.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_data_io.dart';

/// Parses a soroban contract byte code to get Environment Meta, Contract Spec and Contract Meta.
/// see: https://developers.stellar.org/docs/tools/sdks/build-your-own
class SorobanContractParser {
  /// Parses a soroban contract [byteCode] to get Environment Meta, Contract Spec and Contract Meta.
  /// see: https://developers.stellar.org/docs/tools/sdks/build-your-own
  /// Returns [SorobanContractInfo] containing the parsed data.
  /// Throws [SorobanContractParserFailed] if any exception occurred during the byte code parsing. E.g. invalid byte code.
  static SorobanContractInfo parseContractByteCode(Uint8List byteCode) {
    String bytesString = new String.fromCharCodes(byteCode);
    var xdrEnvMeta = _parseEnvironmentMeta(bytesString);
    if (xdrEnvMeta == null || xdrEnvMeta.interfaceVersion == null) {
      throw SorobanContractParserFailed(
          'invalid byte code: environment meta not found.');
    }
    var specEntries = _parseContractSpec(bytesString);
    if (specEntries == null) {
      throw SorobanContractParserFailed(
          'invalid byte code: spec entries not found.');
    }
    var metaEntries = _parseMeta(bytesString);

    return SorobanContractInfo(
        xdrEnvMeta.interfaceVersion!.uint64, specEntries, metaEntries);
  }

  static XdrSCEnvMetaEntry? _parseEnvironmentMeta(String bytesString) {
    try {
      var metaEnvEntryBytes = _extractStringBetween(
          bytesString, 'contractenvmetav0', 'contractmetav0');
      if (metaEnvEntryBytes == null) {
        metaEnvEntryBytes = _extractStringBetween(
            bytesString, 'contractenvmetav0', 'contractspecv0');
      }
      if (metaEnvEntryBytes == null) {
        metaEnvEntryBytes =
            _extractStringToEnd(bytesString, 'contractenvmetav0');
      }

      if (metaEnvEntryBytes == null) {
        return null;
      }

      var bytes = new Uint8List.fromList(metaEnvEntryBytes.codeUnits);
      return XdrSCEnvMetaEntry.decode(XdrDataInputStream(bytes));
    } on Exception catch (_) {
      return null;
    } on Error catch (_) {
      return null;
    }
  }

  static List<XdrSCSpecEntry>? _parseContractSpec(String bytesString) {
    var specBytesString = _extractStringBetween(
        bytesString, 'contractspecv0', 'contractenvmetav0');
    if (specBytesString == null) {
      specBytesString = _extractStringBetween(
          bytesString, 'contractspecv0', 'contractspecv0');
    }
    if (specBytesString == null) {
      specBytesString = _extractStringToEnd(bytesString, 'contractspecv0');
    }

    if (specBytesString == null) {
      return null;
    }
    List<XdrSCSpecEntry> result = List<XdrSCSpecEntry>.empty(growable: true);

    while (specBytesString!.length > 0) {
      try {
        var bytes = new Uint8List.fromList(specBytesString.codeUnits);
        var entry = XdrSCSpecEntry.decode(XdrDataInputStream(bytes));
        if (entry.discriminant ==
                XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0 ||
            entry.discriminant ==
                XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0 ||
            entry.discriminant ==
                XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0 ||
            entry.discriminant ==
                XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0 ||
            entry.discriminant ==
                XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0 ||
            entry.discriminant == XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0) {
          result.add(entry);
          XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
          XdrSCSpecEntry.encode(xdrOutputStream, entry);
          var entryBytes = xdrOutputStream.bytes;
          var entryBytesString = new String.fromCharCodes(entryBytes);
          var specBytesStrOrNull =
              _extractStringToEnd(specBytesString, entryBytesString);
          if (specBytesStrOrNull == null) {
            break;
          }
          specBytesString = specBytesStrOrNull;
        } else {
          break;
        }
      } on Exception catch (_) {
        break;
      } on Error catch (_) {
        break;
      }
    }
    return result;
  }

  static Map<String, String> _parseMeta(String bytesString) {
    var metaBytesString = _extractStringBetween(
        bytesString, 'contractmetav0', 'contractenvmetav0');
    if (metaBytesString == null) {
      metaBytesString = _extractStringBetween(
          bytesString, 'contractmetav0', 'contractspecv0');
    }
    if (metaBytesString == null) {
      metaBytesString = _extractStringToEnd(bytesString, 'contractmetav0');
    }

    Map<String, String> result = Map<String, String>();

    if (metaBytesString == null) {
      return result;
    }

    while (metaBytesString!.length > 0) {
      try {
        var bytes = new Uint8List.fromList(metaBytesString.codeUnits);
        var entry = XdrSCMetaEntry.decode(XdrDataInputStream(bytes));
        if (entry.discriminant == XdrSCMetaKind.SC_META_V0) {
          result[entry.v0!.key] = entry.v0!.value;
          XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
          XdrSCMetaEntry.encode(xdrOutputStream, entry);
          var entryBytes = xdrOutputStream.bytes;
          var entryBytesString = new String.fromCharCodes(entryBytes);
          var metaBytesStrOrNull =
              _extractStringToEnd(metaBytesString, entryBytesString);
          if (metaBytesStrOrNull == null) {
            break;
          }
          metaBytesString = metaBytesStrOrNull;
        } else {
          break;
        }
      } on Exception catch (_) {
        break;
      } on Error catch (_) {
        break;
      }
    }
    return result;
  }

  static String? _extractStringBetween(
      String input, String startSymbol, String endSymbol) {
    int startIndex = input.indexOf(startSymbol);
    int endIndex = input.indexOf(endSymbol, startIndex + startSymbol.length);

    if (startIndex != -1 && endIndex != -1) {
      return input.substring(startIndex + startSymbol.length, endIndex);
    }

    return null;
  }

  static String? _extractStringToEnd(String input, String startSymbol) {
    int startIndex = input.indexOf(startSymbol);

    if (startIndex != -1) {
      return input.substring(startIndex + startSymbol.length);
    }

    return null;
  }
}

/// Thrown if the [SorobanContractParser] failed parsing the given byte code.
class SorobanContractParserFailed implements Exception {
  String _message;

  SorobanContractParserFailed(this._message);

  String toString() {
    return _message;
  }
}

/// Stores information parsed from a soroban contract byte code such as
/// Environment Meta, Contract Spec Entries and Contract Meta Entries.
/// See also: https://developers.stellar.org/docs/tools/sdks/build-your-own
class SorobanContractInfo {
  /**
   * Environment interface number from Environment Meta.
   */
  int envInterfaceVersion;

  /**
   * Contract Spec Entries. There is a SCSpecEntry for every function, struct,
   * and union exported by the contract.
   */
  List<XdrSCSpecEntry> specEntries;

  /**
   * Contract Meta Entries. Key => Value pairs.
   * Contracts may store any metadata in the entries that can be used by applications
   * and tooling off-network.
   */
  Map<String, String> metaEntries;

  /**
   * List of SEPs (Stellar Ecosystem Proposals) supported by the contract.
   * Extracted from the "sep" meta entry as defined in SEP-47.
   * Contains SEP numbers as strings (e.g., "1", "10", "24", "47").
   */
  List<String> supportedSeps;

  /**
   * Contract functions extracted from spec entries.
   * Contains all function specifications exported by the contract.
   */
  List<XdrSCSpecFunctionV0> funcs;

  /**
   * User-defined type structs extracted from spec entries.
   * Contains all UDT struct specifications exported by the contract.
   */
  List<XdrSCSpecUDTStructV0> udtStructs;

  /**
   * User-defined type unions extracted from spec entries.
   * Contains all UDT union specifications exported by the contract.
   */
  List<XdrSCSpecUDTUnionV0> udtUnions;

  /**
   * User-defined type enums extracted from spec entries.
   * Contains all UDT enum specifications exported by the contract.
   */
  List<XdrSCSpecUDTEnumV0> udtEnums;

  /**
   * User-defined type error enums extracted from spec entries.
   * Contains all UDT error enum specifications exported by the contract.
   */
  List<XdrSCSpecUDTErrorEnumV0> udtErrorEnums;

  /**
   * Event specifications extracted from spec entries.
   * Contains all event specifications exported by the contract.
   */
  List<XdrSCSpecEventV0> events;

  /**
   * Constructor.
   */
  SorobanContractInfo(
      this.envInterfaceVersion, this.specEntries, this.metaEntries)
      : supportedSeps = _parseSupportedSeps(metaEntries),
        funcs = _extractFunctions(specEntries),
        udtStructs = _extractUdtStructs(specEntries),
        udtUnions = _extractUdtUnions(specEntries),
        udtEnums = _extractUdtEnums(specEntries),
        udtErrorEnums = _extractUdtErrorEnums(specEntries),
        events = _extractEvents(specEntries);

  /**
   * Parses the supported SEPs from the meta entries.
   * The "sep" meta entry contains a comma-separated list of SEP numbers (e.g., "1, 10, 24").
   * Duplicates are automatically removed while preserving order.
   */
  static List<String> _parseSupportedSeps(Map<String, String> metaEntries) {
    var sepValue = metaEntries['sep'];
    if (sepValue == null || sepValue.isEmpty) {
      return [];
    }
    return sepValue
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
  }

  /**
   * Extract function specifications from spec entries.
   * Iterates through all spec entries and collects those that define functions.
   */
  static List<XdrSCSpecFunctionV0> _extractFunctions(
      List<XdrSCSpecEntry> specEntries) {
    List<XdrSCSpecFunctionV0> result =
        List<XdrSCSpecFunctionV0>.empty(growable: true);

    for (var entry in specEntries) {
      if (entry.discriminant == XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0 &&
          entry.functionV0 != null) {
        result.add(entry.functionV0!);
      }
    }

    return result;
  }

  /**
   * Extract UDT struct specifications from spec entries.
   * Iterates through all spec entries and collects those that define user-defined type structs.
   */
  static List<XdrSCSpecUDTStructV0> _extractUdtStructs(
      List<XdrSCSpecEntry> specEntries) {
    List<XdrSCSpecUDTStructV0> result =
        List<XdrSCSpecUDTStructV0>.empty(growable: true);

    for (var entry in specEntries) {
      if (entry.discriminant ==
              XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0 &&
          entry.udtStructV0 != null) {
        result.add(entry.udtStructV0!);
      }
    }

    return result;
  }

  /**
   * Extract UDT union specifications from spec entries.
   * Iterates through all spec entries and collects those that define user-defined type unions.
   */
  static List<XdrSCSpecUDTUnionV0> _extractUdtUnions(
      List<XdrSCSpecEntry> specEntries) {
    List<XdrSCSpecUDTUnionV0> result =
        List<XdrSCSpecUDTUnionV0>.empty(growable: true);

    for (var entry in specEntries) {
      if (entry.discriminant == XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0 &&
          entry.udtUnionV0 != null) {
        result.add(entry.udtUnionV0!);
      }
    }

    return result;
  }

  /**
   * Extract UDT enum specifications from spec entries.
   * Iterates through all spec entries and collects those that define user-defined type enums.
   */
  static List<XdrSCSpecUDTEnumV0> _extractUdtEnums(
      List<XdrSCSpecEntry> specEntries) {
    List<XdrSCSpecUDTEnumV0> result =
        List<XdrSCSpecUDTEnumV0>.empty(growable: true);

    for (var entry in specEntries) {
      if (entry.discriminant == XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0 &&
          entry.udtEnumV0 != null) {
        result.add(entry.udtEnumV0!);
      }
    }

    return result;
  }

  /**
   * Extract UDT error enum specifications from spec entries.
   * Iterates through all spec entries and collects those that define user-defined type error enums.
   */
  static List<XdrSCSpecUDTErrorEnumV0> _extractUdtErrorEnums(
      List<XdrSCSpecEntry> specEntries) {
    List<XdrSCSpecUDTErrorEnumV0> result =
        List<XdrSCSpecUDTErrorEnumV0>.empty(growable: true);

    for (var entry in specEntries) {
      if (entry.discriminant ==
              XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0 &&
          entry.udtErrorEnumV0 != null) {
        result.add(entry.udtErrorEnumV0!);
      }
    }

    return result;
  }

  /**
   * Extract event specifications from spec entries.
   * Iterates through all spec entries and collects those that define events.
   */
  static List<XdrSCSpecEventV0> _extractEvents(
      List<XdrSCSpecEntry> specEntries) {
    List<XdrSCSpecEventV0> result =
        List<XdrSCSpecEventV0>.empty(growable: true);

    for (var entry in specEntries) {
      if (entry.discriminant == XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0 &&
          entry.eventV0 != null) {
        result.add(entry.eventV0!);
      }
    }

    return result;
  }
}
