// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Tests for the embedded Stellar Asset Contract spec: the constants of
// SACSpec, the decoded entries of SACClient.specEntries(), and the strict
// decoding of SACClient.decodeSpec(). The byte vectors of the decoding tests
// are written out in the test; their digests are computed with Util.hash.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const List<String> _functionNames = [
  'admin',
  'allowance',
  'approve',
  'authorized',
  'balance',
  'burn',
  'burn_from',
  'clawback',
  'decimals',
  'mint',
  'name',
  'set_admin',
  'set_authorized',
  'symbol',
  'transfer',
  'transfer_from',
  'trust',
];

const List<String> _eventNames = [
  'Approve',
  'Burn',
  'Clawback',
  'Mint',
  'MintWithAmountOnly',
  'MintWithMuxedBytes',
  'MintWithMuxedString',
  'SetAdmin',
  'SetAuthorized',
  'Transfer',
  'TransferWithAmountOnly',
  'TransferWithMuxedBytes',
  'TransferWithMuxedString',
];

String _sha256Hex(List<int> bytes) =>
    Util.bytesToHex(Util.hash(Uint8List.fromList(bytes)));

Uint8List _specBytes() => base64Decode(SACSpec.XDR_BASE64);

/// The XDR encoding of one entry, as the decoder sees it.
Uint8List _encodeEntry(XdrSCSpecEntry entry) {
  final stream = XdrDataOutputStream();
  XdrSCSpecEntry.encode(stream, entry);
  return Uint8List.fromList(stream.bytes);
}

/// E: a synthetic function entry named `balance`, as bytes. It is 28 bytes:
/// kind 0 (function), doc length 0, name length 7 with "balance" and one zero
/// padding byte, no inputs, no outputs.
final List<int> _entryE = [
  0x00, 0x00, 0x00, 0x00, // kind: SC_SPEC_ENTRY_FUNCTION_V0
  0x00, 0x00, 0x00, 0x00, // doc: empty
  0x00, 0x00, 0x00, 0x07, // name length
  0x62, 0x61, 0x6c, 0x61, 0x6e, 0x63, 0x65, // "balance"
  0x00, // padding
  0x00, 0x00, 0x00, 0x00, // inputs: none
  0x00, 0x00, 0x00, 0x00, // outputs: none
];

/// E with the kind replaced by [kind], as a signed 32-bit value.
List<int> _entryWithKind(int kind) {
  final bytes = List<int>.from(_entryE);
  bytes[0] = (kind >> 24) & 0xFF;
  bytes[1] = (kind >> 16) & 0xFF;
  bytes[2] = (kind >> 8) & 0xFF;
  bytes[3] = kind & 0xFF;
  return bytes;
}

/// An entry whose doc is the UTF-8 byte order mark EF BB BF, with one zero
/// padding byte.
final List<int> _bomEntry = [
  0x00, 0x00, 0x00, 0x00, // kind: SC_SPEC_ENTRY_FUNCTION_V0
  0x00, 0x00, 0x00, 0x03, // doc length
  0xEF, 0xBB, 0xBF, 0x00, // byte order mark, padding
  0x00, 0x00, 0x00, 0x07, // name length
  0x62, 0x61, 0x6c, 0x61, 0x6e, 0x63, 0x65, // "balance"
  0x00, // padding
  0x00, 0x00, 0x00, 0x00, // inputs: none
  0x00, 0x00, 0x00, 0x00, // outputs: none
];

void main() {
  group('SACSpec constants', () {
    test('the decoded XDR is 9612 bytes with the pinned sha256', () {
      final bytes = _specBytes();
      expect(bytes, hasLength(9612));
      expect(_sha256Hex(bytes), SACSpec.SHA256);
    });

    test('XDR_BASE64 has 12816 characters', () {
      expect(SACSpec.XDR_BASE64, hasLength(12816));
    });

    test('SHA256 and UPSTREAM_COMMIT are the pinned literals', () {
      expect(
        SACSpec.SHA256,
        'a88030febc66645d40b96deba8be16a6eb13c213768b4c1f9cd6278080d74669',
      );
      expect(
        SACSpec.UPSTREAM_COMMIT,
        '4f08d14f8b3e09e195f2cc4aab51c7f8a34f52ea',
      );
    });
  });

  group('SACClient.specEntries', () {
    test('has 30 entries, each a function or an event', () {
      final entries = SACClient.specEntries();
      expect(entries, hasLength(30));
      for (final entry in entries) {
        expect(
          entry.discriminant == XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0 ||
              entry.discriminant == XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0,
          isTrue,
          reason: 'entry kind ${entry.discriminant}',
        );
      }
    });

    test('has the 17 functions and 13 events of the spec', () {
      final entries = SACClient.specEntries();
      final functions = <String>[];
      final events = <String>[];
      for (final entry in entries) {
        if (entry.discriminant ==
            XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0) {
          functions.add(entry.functionV0!.name);
        } else {
          events.add(entry.eventV0!.name);
        }
      }
      expect(functions, hasLength(17));
      expect(events, hasLength(13));
      expect(functions..sort(), _functionNames);
      expect(events..sort(), _eventNames);
    });

    test('the entries re-encode to the decoded bytes', () {
      final out = XdrDataOutputStream();
      for (final entry in SACClient.specEntries()) {
        XdrSCSpecEntry.encode(out, entry);
      }
      expect(out.bytes, _specBytes());
    });

    test('two calls return distinct entries that encode equally', () {
      final first = SACClient.specEntries();
      final second = SACClient.specEntries();
      expect(first, hasLength(second.length));
      for (var i = 0; i < first.length; i++) {
        expect(identical(first[i], second[i]), isFalse, reason: 'index $i');
        expect(_encodeEntry(first[i]), _encodeEntry(second[i]));
      }
    });

    test('balance, decimals, name, symbol, and transfer match the spec', () {
      final entries = SACClient.specEntries();
      XdrSCSpecFunctionV0 function(String name) => entries
          .map((entry) => entry.functionV0)
          .whereType<XdrSCSpecFunctionV0>()
          .firstWhere((f) => f.name == name);

      final balance = function('balance');
      expect(balance.inputs, hasLength(1));
      expect(balance.inputs[0].name, 'id');
      expect(
        balance.inputs[0].type.discriminant,
        XdrSCSpecType.SC_SPEC_TYPE_ADDRESS,
      );
      expect(balance.outputs, hasLength(1));
      expect(balance.outputs[0].discriminant, XdrSCSpecType.SC_SPEC_TYPE_I128);

      final decimals = function('decimals');
      expect(decimals.inputs, isEmpty);
      expect(decimals.outputs, hasLength(1));
      expect(decimals.outputs[0].discriminant, XdrSCSpecType.SC_SPEC_TYPE_U32);

      for (final name in ['name', 'symbol']) {
        final f = function(name);
        expect(f.inputs, isEmpty, reason: name);
        expect(f.outputs, hasLength(1), reason: name);
        expect(
          f.outputs[0].discriminant,
          XdrSCSpecType.SC_SPEC_TYPE_STRING,
          reason: name,
        );
      }

      final transfer = function('transfer');
      expect(transfer.inputs.map((i) => i.name), ['from', 'to', 'amount']);
      expect(transfer.inputs.map((i) => i.type.discriminant), [
        XdrSCSpecType.SC_SPEC_TYPE_ADDRESS,
        XdrSCSpecType.SC_SPEC_TYPE_MUXED_ADDRESS,
        XdrSCSpecType.SC_SPEC_TYPE_I128,
      ]);
      expect(transfer.outputs, isEmpty);
    });
  });

  group('SACClient.decodeSpec failures', () {
    test('a sha256 that does not match names both digests', () {
      final text = SACSpec.XDR_BASE64;
      final truncated = text.substring(0, text.length - 4);
      expect(
        () => SACClient.decodeSpec(truncated, SACSpec.SHA256),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'The embedded SAC spec has sha256 '
                '0c15c7a293dba569d8a304726d3571816a6f7dda83382874004d7977b31b2460, '
                'expected '
                'a88030febc66645d40b96deba8be16a6eb13c213768b4c1f9cd6278080d74669',
          ),
        ),
      );
    });

    test('text that is not base64 gives the base64 message', () {
      expect(
        () => SACClient.decodeSpec('@@@@', SACSpec.SHA256),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'The embedded SAC spec is not valid base64',
          ),
        ),
      );
    });

    test('an unknown entry kind after the last entry fails at offset 9612', () {
      final bytes = Uint8List.fromList([
        ..._specBytes(),
        0xFF,
        0xFF,
        0xFF,
        0xFF,
      ]);
      expect(
        () => SACClient.decodeSpec(base64Encode(bytes), _sha256Hex(bytes)),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'The embedded SAC spec does not decode at byte offset 9612: '
                'Exception: Unknown enum value: -1',
          ),
        ),
      );
    });

    group('one function entry E', () {
      test('E itself decodes and re-encodes', () {
        final bytes = Uint8List.fromList(_entryE);
        expect(bytes, hasLength(28));
        final entries = SACClient.decodeSpec(
          base64Encode(bytes),
          _sha256Hex(bytes),
        );
        expect(entries, hasLength(1));
        expect(entries[0].functionV0!.name, 'balance');
        expect(entries[0].functionV0!.inputs, isEmpty);
        expect(entries[0].functionV0!.outputs, isEmpty);
        expect(_encodeEntry(entries[0]), bytes);
      });

      test('an unknown entry kind fails at offset 0, for each value', () {
        final cases = <(int, String)>[
          (
            6,
            'The embedded SAC spec does not decode at byte offset 0: '
                'Exception: Unknown enum value: 6',
          ),
          (
            255,
            'The embedded SAC spec does not decode at byte offset 0: '
                'Exception: Unknown enum value: 255',
          ),
          (
            2147483647,
            'The embedded SAC spec does not decode at byte offset 0: '
                'Exception: Unknown enum value: 2147483647',
          ),
          (
            -2,
            'The embedded SAC spec does not decode at byte offset 0: '
                'Exception: Unknown enum value: -2',
          ),
        ];
        for (final (kind, message) in cases) {
          final bytes = Uint8List.fromList(_entryWithKind(kind));
          expect(
            () => SACClient.decodeSpec(base64Encode(bytes), _sha256Hex(bytes)),
            throwsA(
              isA<StateError>().having((e) => e.message, 'message', message),
            ),
            reason: 'kind $kind',
          );
        }
      });

      test('a non-zero padding byte after the name fails at offset 0', () {
        final bytes = List<int>.from(_entryE);
        bytes[19] = 0x01;
        final data = Uint8List.fromList(bytes);
        expect(
          () => SACClient.decodeSpec(base64Encode(data), _sha256Hex(data)),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'The embedded SAC spec does not decode at byte offset 0: '
                  'Exception: non-zero padding',
            ),
          ),
        );
      });

      test('E without its last two bytes fails at offset 0', () {
        final bytes = Uint8List.fromList(_entryE.sublist(0, 26));
        expect(
          () => SACClient.decodeSpec(base64Encode(bytes), _sha256Hex(bytes)),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'The embedded SAC spec does not decode at byte offset 0: '
                  'RangeError: XDR read of 4 bytes exceeds the 2 remaining '
                  'bytes',
            ),
          ),
        );
      });
    });

    test('a doc that starts with a byte order mark keeps it', () {
      // The doc is EF BB BF with one zero padding byte.
      final bytes = Uint8List.fromList(_bomEntry);
      final entries = SACClient.decodeSpec(
        base64Encode(bytes),
        _sha256Hex(bytes),
      );
      expect(entries, hasLength(1));
      expect(entries.single.functionV0!.doc, '\uFEFF');
      expect(entries.single.functionV0!.name, 'balance');
      final encoded = XdrDataOutputStream();
      XdrSCSpecEntry.encode(encoded, entries.single);
      expect(encoded.bytes, bytes);
    });

    test('an output without its final padding bytes fails at offset 0', () {
      // One output, UDT("a"), whose three final padding bytes are cut.
      final bytes = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x00, // kind: SC_SPEC_ENTRY_FUNCTION_V0
        0x00, 0x00, 0x00, 0x00, // doc: empty
        0x00, 0x00, 0x00, 0x07, // name length
        0x62, 0x61, 0x6c, 0x61, 0x6e, 0x63, 0x65, // "balance"
        0x00, // padding
        0x00, 0x00, 0x00, 0x00, // inputs: none
        0x00, 0x00, 0x00, 0x01, // outputs: one
        0x00, 0x00, 0x07, 0xD0, // type: SC_SPEC_TYPE_UDT (2000)
        0x00, 0x00, 0x00, 0x01, // UDT name length
        0x61, // "a"
      ]);
      expect(bytes, hasLength(37));
      expect(
        () => SACClient.decodeSpec(base64Encode(bytes), _sha256Hex(bytes)),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'The embedded SAC spec does not decode at byte offset 0: '
                'Exception: XDR input ends inside padding at offset 37',
          ),
        ),
      );
    });
  });

  group('SACClient.decodeSpec keeps the original stack trace', () {
    test('a base64 failure starts at the FormatException trace', () {
      StackTrace? original;
      try {
        base64Decode('@@@@');
      } on FormatException catch (_, stackTrace) {
        original = stackTrace;
      }
      StackTrace? thrown;
      try {
        SACClient.decodeSpec('@@@@', SACSpec.SHA256);
      } on StateError catch (_, stackTrace) {
        thrown = stackTrace;
      }
      expect(original, isNotNull);
      expect(thrown, isNotNull);
      expect(
        thrown.toString().split('\n').first,
        original.toString().split('\n').first,
      );
    });

    test('an entry decode failure starts at the trace of the decoder', () {
      final bytes = Uint8List.fromList(_entryE.sublist(0, 26));
      StackTrace? original;
      try {
        XdrSCSpecEntry.decode(XdrDataInputStream(bytes));
      } on RangeError catch (_, stackTrace) {
        original = stackTrace;
      }
      StackTrace? thrown;
      try {
        SACClient.decodeSpec(base64Encode(bytes), _sha256Hex(bytes));
      } on StateError catch (_, stackTrace) {
        thrown = stackTrace;
      }
      expect(original, isNotNull);
      expect(thrown, isNotNull);
      expect(
        thrown.toString().split('\n').first,
        original.toString().split('\n').first,
      );
    });

    test('a digest mismatch starts at the check in decodeSpec', () {
      final text = SACSpec.XDR_BASE64;
      final truncated = text.substring(0, text.length - 4);
      StackTrace? thrown;
      try {
        SACClient.decodeSpec(truncated, SACSpec.SHA256);
      } on StateError catch (error, stackTrace) {
        thrown = stackTrace;
        expect(
          error.message,
          'The embedded SAC spec has sha256 0c15c7a293dba569d8a304726d3571816a6f7dda83382874004d7977b31b2460, expected a88030febc66645d40b96deba8be16a6eb13c213768b4c1f9cd6278080d74669',
        );
      }
      expect(thrown, isNotNull);
      expect(
        thrown.toString().split('\n').take(2).join('\n'),
        contains('decodeSpec'),
      );
    });
  });
}
