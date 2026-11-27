// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/util.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr.dart';

/// Parser for extracting metadata from Soroban contract WebAssembly bytecode.
///
/// SorobanContractParser extracts embedded metadata from compiled contract WASM files,
/// including environment version, function specifications, and contract metadata.
/// This metadata is essential for understanding contract interfaces and invoking functions.
///
/// The parser extracts:
/// - Environment Meta: Protocol version and interface numbers
/// - Contract Spec: Function signatures, types, and event schemas
/// - Contract Meta: Key-value metadata pairs (contract name, version, SEP support, etc.)
///
/// They are read from the wasm custom sections `contractenvmetav0`,
/// `contractspecv0` and `contractmetav0`, each a stream of XDR entries. The
/// first `contractenvmetav0` and the first `contractspecv0` section are used;
/// all `contractmetav0` sections are read in module order, as SEP-46 defines.
///
/// This parser is used internally by SorobanServer when loading contract information,
/// but can also be used directly when working with raw WASM bytecode.
///
/// See also:
/// - [SorobanServer.loadContractInfoForContractId] for automatic contract loading
/// - [SorobanContractInfo] for parsed contract information
/// - [Soroban SDK Build Guide](https://developers.stellar.org/docs/tools/sdks/build-your-own)
class SorobanContractParser {
  /// Parses Soroban contract WebAssembly bytecode to extract metadata.
  ///
  /// Extracts environment metadata, contract specifications (functions, types, events),
  /// and contract metadata (name, version, SEP support) from the WASM bytecode.
  ///
  /// Parameters:
  /// - [byteCode] Raw WASM bytecode of the compiled Soroban contract
  ///
  /// Returns: [SorobanContractInfo] containing:
  /// - envProtocolVersion: Environment protocol version number
  /// - specEntries: Function and type specifications
  /// - metaEntries: Contract metadata key-value pairs
  /// - supportedSeps: List of supported SEP numbers
  /// - Extracted functions, structs, unions, enums, and events
  ///
  /// Throws:
  /// - [SorobanContractParserFailed] If [byteCode] has no wasm header, a
  ///   section size or a custom section name runs past its bounds, the
  ///   environment meta or the spec section is missing, the first environment
  ///   meta section holds no entry, or an entry of one of the three sections
  ///   does not decode, has an unknown kind or is cut off by the end of its
  ///   section. Framing and entry decoding errors name the byte offset in
  ///   [byteCode].
  ///
  /// Example:
  /// ```dart
  /// // Load contract WASM file
  /// final wasmBytes = await File('contract.wasm').readAsBytes();
  ///
  /// // Parse contract metadata
  /// final contractInfo = SorobanContractParser.parseContractByteCode(wasmBytes);
  ///
  /// print('Environment version: ${contractInfo.envProtocolVersion}');
  /// print('Functions: ${contractInfo.funcs.map((f) => f.name).join(', ')}');
  /// print('Supported SEPs: ${contractInfo.supportedSeps}');
  ///
  /// // Access contract metadata
  /// if (contractInfo.metaEntries.containsKey('name')) {
  ///   print('Contract name: ${contractInfo.metaEntries['name']}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [SorobanContractInfo] for details on parsed data
  /// - [SorobanServer.loadContractCodeForContractId] to get contract bytecode
  static SorobanContractInfo parseContractByteCode(Uint8List byteCode) {
    final sections = _readContractSections(byteCode);
    final interfaceVersion = _parseEnvironmentMeta(
      byteCode,
      sections[_envMetaSectionName],
    );
    if (interfaceVersion == null) {
      throw SorobanContractParserFailed(
        'invalid byte code: environment meta not found.',
      );
    }
    final specEntries = _parseContractSpec(
      byteCode,
      sections[_specSectionName],
    );
    if (specEntries == null) {
      throw SorobanContractParserFailed(
        'invalid byte code: spec entries not found.',
      );
    }
    final metaEntries = _parseMeta(byteCode, sections[_metaSectionName]);

    return SorobanContractInfo(
      interfaceVersion.protocol.uint32,
      interfaceVersion.preRelease.uint32,
      specEntries,
      metaEntries,
    );
  }

  static const String _envMetaSectionName = 'contractenvmetav0';
  static const String _specSectionName = 'contractspecv0';
  static const String _metaSectionName = 'contractmetav0';
  static const int _customSectionId = 0;

  /// Returns the interface version of the first entry of the first
  /// [_envMetaSectionName] section, or null without such an entry.
  static XdrSCEnvMetaEntryInterfaceVersion? _parseEnvironmentMeta(
    Uint8List byteCode,
    List<_ContractSection>? sections,
  ) {
    if (sections == null) {
      return null;
    }
    final entries = _decodeEntries(
      byteCode,
      _envMetaSectionName,
      sections.first,
      XdrSCEnvMetaEntry.decode,
    );
    // SC_ENV_META_KIND_INTERFACE_VERSION is the only environment meta kind.
    return entries.isEmpty ? null : entries.first.interfaceVersion;
  }

  /// Returns the entries of the first [_specSectionName] section, or null
  /// without such a section.
  static List<XdrSCSpecEntry>? _parseContractSpec(
    Uint8List byteCode,
    List<_ContractSection>? sections,
  ) {
    if (sections == null) {
      return null;
    }
    return _decodeEntries(
      byteCode,
      _specSectionName,
      sections.first,
      XdrSCSpecEntry.decode,
    );
  }

  /// Returns the key-value pairs of every [_metaSectionName] section in
  /// module order. A later entry with the same key replaces an earlier one,
  /// except that the values of repeated `sep` entries are joined with a
  /// comma, as SEP-47 defines.
  static Map<String, String> _parseMeta(
    Uint8List byteCode,
    List<_ContractSection>? sections,
  ) {
    final result = <String, String>{};
    for (final section in sections ?? const <_ContractSection>[]) {
      final entries = _decodeEntries(
        byteCode,
        _metaSectionName,
        section,
        XdrSCMetaEntry.decode,
      );
      // SC_META_V0 is the only meta kind.
      for (final entry in entries) {
        final key = entry.v0!.key;
        result[key] = key == 'sep'
            ? _appendSepValue(result[key], entry.v0!.val)
            : entry.v0!.val;
      }
    }
    return result;
  }

  /// Returns [value] after [current] with a comma between them, or [value]
  /// when [current] is null.
  static String _appendSepValue(String? current, String value) =>
      current == null ? value : '$current,$value';

  /// Walks the sections of the wasm module [byteCode] and returns, per name,
  /// the content bounds of the custom sections [_envMetaSectionName],
  /// [_specSectionName] and [_metaSectionName] in module order.
  ///
  /// Every section is checked: its size must lie within the module, and the
  /// name of a custom section within its section. The content of the other
  /// sections is not read, so their bytes never start a contract section.
  static Map<String, List<_ContractSection>> _readContractSections(
    Uint8List byteCode,
  ) {
    // The header is the 4-byte magic and the 4-byte version.
    if (byteCode.length < 8) {
      throw SorobanContractParserFailed(
        'invalid byte code: the ${byteCode.length} bytes at byte offset 0 '
        'are shorter than the 8-byte wasm header.',
      );
    }
    _checkHeaderField(byteCode, 0, 'magic', const [0x00, 0x61, 0x73, 0x6d]);
    _checkHeaderField(byteCode, 4, 'version', const [0x01, 0x00, 0x00, 0x00]);

    final sections = <String, List<_ContractSection>>{};
    var offset = 8;
    while (offset < byteCode.length) {
      final id = byteCode[offset];
      final (size, payloadStart) = _readVarUint32(
        byteCode,
        offset + 1,
        byteCode.length,
        'size of the section at byte offset $offset',
      );
      final remaining = byteCode.length - payloadStart;
      if (size > remaining) {
        throw SorobanContractParserFailed(
          'invalid byte code: the section with id $id at byte offset $offset '
          'declares $size bytes, but $remaining bytes remain.',
        );
      }
      final end = payloadStart + size;
      if (id == _customSectionId) {
        final (nameLength, nameStart) = _readVarUint32(
          byteCode,
          payloadStart,
          end,
          'name length of the custom section at byte offset $offset',
        );
        if (nameLength > end - nameStart) {
          throw SorobanContractParserFailed(
            'invalid byte code: the custom section at byte offset $offset '
            'declares a $nameLength-byte name, but ${end - nameStart} bytes '
            'of the section remain.',
          );
        }
        final contentStart = nameStart + nameLength;
        final name = String.fromCharCodes(byteCode, nameStart, contentStart);
        if (name == _envMetaSectionName ||
            name == _specSectionName ||
            name == _metaSectionName) {
          (sections[name] ??= []).add((start: contentStart, end: end));
        }
      }
      offset = end;
    }
    return sections;
  }

  static void _checkHeaderField(
    Uint8List byteCode,
    int offset,
    String field,
    List<int> expected,
  ) {
    for (var i = 0; i < expected.length; i++) {
      if (byteCode[offset + i] != expected[i]) {
        final actual = byteCode.sublist(offset, offset + expected.length);
        throw SorobanContractParserFailed(
          'invalid byte code: the wasm $field at byte offset $offset is '
          '${Util.bytesToHex(actual)}, expected '
          '${Util.bytesToHex(Uint8List.fromList(expected))}.',
        );
      }
    }
  }

  /// Reads the unsigned LEB128 u32 [field] that starts at [offset] and must
  /// end before [limit]; returns its value and the offset after it.
  ///
  /// A padded encoding of up to 5 bytes is accepted, as in the wasm binary
  /// format.
  static (int, int) _readVarUint32(
    Uint8List bytes,
    int offset,
    int limit,
    String field,
  ) {
    var value = 0;
    var shift = 0;
    var position = offset;
    while (true) {
      if (position >= limit) {
        throw SorobanContractParserFailed(
          'invalid byte code: the $field ends at byte offset $limit before '
          'its last byte.',
        );
      }
      final byte = bytes[position++];
      // The fifth byte holds bits 28 to 31 and must be the last.
      if (shift == 28 && byte > 0x0f) {
        final problem = (byte & 0x80) != 0
            ? 'is longer than 5 bytes'
            : 'exceeds the u32 range';
        throw SorobanContractParserFailed(
          'invalid byte code: the $field $problem.',
        );
      }
      value |= (byte & 0x7f) << shift;
      if ((byte & 0x80) == 0) {
        return (value, position);
      }
      shift += 7;
    }
  }

  /// Decodes the content of [section] as a stream of entries with [decode]
  /// until the content ends.
  ///
  /// Throws a [SorobanContractParserFailed] that names [sectionName] and the
  /// byte offset of the entry in [byteCode] when an entry does not decode,
  /// including an unknown kind and bytes at the end that are not a whole entry.
  static List<T> _decodeEntries<T>(
    Uint8List byteCode,
    String sectionName,
    _ContractSection section,
    T Function(XdrDataInputStream stream) decode,
  ) {
    final stream = XdrDataInputStream(
      Uint8List.sublistView(byteCode, section.start, section.end),
    );
    final entries = <T>[];
    while (stream.offset! < stream.fileLength!) {
      final entryOffset = section.start + stream.offset!;
      try {
        entries.add(decode(stream));
      } on Exception catch (e) {
        throw _entryFailure(sectionName, entryOffset, e);
      } on Error catch (e) {
        throw _entryFailure(sectionName, entryOffset, e);
      }
    }
    return entries;
  }

  static SorobanContractParserFailed _entryFailure(
    String sectionName,
    int entryOffset,
    Object cause,
  ) {
    return SorobanContractParserFailed(
      'invalid byte code: the $sectionName entry at byte offset $entryOffset '
      'does not decode: $cause',
    );
  }
}

/// The content bounds of a wasm custom section: [start] is the offset of its
/// first content byte in the module, [end] the offset after its last.
typedef _ContractSection = ({int start, int end});

/// Thrown if the [SorobanContractParser] failed parsing the given byte code.
class SorobanContractParserFailed implements Exception {
  String _message;

  /// Creates a SorobanContractParserFailed exception with error description.
  ///
  /// This exception is thrown when contract WASM bytecode cannot be parsed,
  /// typically due to invalid format, missing metadata sections, or corrupted data.
  ///
  /// Parameters:
  /// - [_message] Description of the parsing failure (e.g., "environment meta not found")
  SorobanContractParserFailed(this._message);

  /// Returns error message describing the parsing failure.
  @override
  String toString() {
    return _message;
  }
}

/// Container for metadata extracted from Soroban contract bytecode.
///
/// SorobanContractInfo holds all metadata parsed from a contract's WebAssembly bytecode,
/// including environment version, function specifications, type definitions, and contract metadata.
///
/// This information is essential for:
/// - Understanding contract capabilities and functions
/// - Converting arguments to the correct types
/// - Discovering SEP support and contract features
/// - Validating contract compatibility
///
/// The info is automatically populated when using SorobanServer.loadContractInfoForContractId()
/// or can be manually created by parsing WASM bytecode.
///
/// Example:
/// ```dart
/// // Load contract info from deployed contract
/// final server = SorobanServer(rpcUrl);
/// final contractInfo = await server.loadContractInfoForContractId(contractId);
///
/// if (contractInfo != null) {
///   print('Environment version: ${contractInfo.envProtocolVersion}');
///
///   // List available functions
///   for (final func in contractInfo.funcs) {
///     print('Function: ${func.name}');
///     print('  Inputs: ${func.inputs.map((i) => i.name).join(', ')}');
///   }
///
///   // Check SEP support
///   if (contractInfo.supportedSeps.contains('41')) {
///     print('Token interface supported');
///   }
///
///   // Access metadata
///   if (contractInfo.metaEntries.containsKey('description')) {
///     print('Description: ${contractInfo.metaEntries['description']}');
///   }
/// }
/// ```
///
/// See also:
/// - [SorobanContractParser] for parsing contract bytecode
/// - [SorobanServer.loadContractInfoForContractId] for loading contract info
/// - [ContractSpec] for using spec entries in type conversion
class SorobanContractInfo {
  /// Environment protocol version number from the contract metadata.
  int envProtocolVersion;

  /// Environment pre-release version number from the contract metadata.
  int envPreReleaseVersion;

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

  /// Creates SorobanContractInfo from parsed contract metadata.
  ///
  /// Parameters:
  /// - [envProtocolVersion] Environment protocol version number
  /// - [envPreReleaseVersion] Environment pre-release version number
  /// - [specEntries] Contract specification entries (functions, types, events)
  /// - [metaEntries] Contract metadata key-value pairs
  ///
  /// Automatically extracts and organizes contract elements from spec entries.
  SorobanContractInfo(
    this.envProtocolVersion,
    this.envPreReleaseVersion,
    this.specEntries,
    this.metaEntries,
  ) : supportedSeps = _parseSupportedSeps(metaEntries),
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
    List<XdrSCSpecEntry> specEntries,
  ) {
    List<XdrSCSpecFunctionV0> result = List<XdrSCSpecFunctionV0>.empty(
      growable: true,
    );

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
    List<XdrSCSpecEntry> specEntries,
  ) {
    List<XdrSCSpecUDTStructV0> result = List<XdrSCSpecUDTStructV0>.empty(
      growable: true,
    );

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
    List<XdrSCSpecEntry> specEntries,
  ) {
    List<XdrSCSpecUDTUnionV0> result = List<XdrSCSpecUDTUnionV0>.empty(
      growable: true,
    );

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
    List<XdrSCSpecEntry> specEntries,
  ) {
    List<XdrSCSpecUDTEnumV0> result = List<XdrSCSpecUDTEnumV0>.empty(
      growable: true,
    );

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
    List<XdrSCSpecEntry> specEntries,
  ) {
    List<XdrSCSpecUDTErrorEnumV0> result = List<XdrSCSpecUDTErrorEnumV0>.empty(
      growable: true,
    );

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
    List<XdrSCSpecEntry> specEntries,
  ) {
    List<XdrSCSpecEventV0> result = List<XdrSCSpecEventV0>.empty(
      growable: true,
    );

    for (var entry in specEntries) {
      if (entry.discriminant == XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0 &&
          entry.eventV0 != null) {
        result.add(entry.eventV0!);
      }
    }

    return result;
  }
}
