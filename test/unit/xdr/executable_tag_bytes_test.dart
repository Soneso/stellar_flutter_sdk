// Tests for the CAP-85 executable tag, an XDR string the SDK carries as raw
// bytes. Every value an XDR string admits must survive decode, encode, the
// SEP-0051 rendering and the TxRep rendering, and a tag read off the ledger
// must build the ledger key of the entry it came from.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/xdr/txrep_helper.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  const ownerContractIdHex =
      'c5b1f9f0c3a2d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d';
  const ownerStrKey = 'CDC3D6PQYORNJZPWA4MCSOSLLRWX5D4QUGZMHVHF6YDRQKJ2JNOG3LTZ';

  XdrSCAddress owner() => XdrSCAddress.forContractId(ownerContractIdHex);

  // A tag whose bytes are not valid UTF-8. 0xC0 begins no UTF-8 sequence and
  // 0xFF appears in none, so the value has no text spelling at all.
  final binaryTag = Uint8List.fromList(<int>[0xC0, 0x00, 0xFF, 0xFE]);

  // Text exercising every rung of both escape ladders: multi-byte UTF-8, an
  // astral code point, a tab, a quote, a backslash, a newline and DEL.
  final textTag = String.fromCharCodes(<int>[
    0x61, // a
    0xE9, // e acute
    0x20AC, // euro sign
    0x1F600, // grinning face
    0x09, // tab
    0x22, // quote
    0x5C, // backslash
    0x0A, // newline
    0x7F, // delete
    0x7A, // z
  ]);
  final textTagBytes = Uint8List.fromList(utf8.encode(textTag));

  // The renderings a text tag has always had. Pinned so the bytes-backed
  // representation cannot change the wire, the JSON or the TxRep of a value
  // that spells text.
  const simpleRefXdr =
      'AAAAAcWx+fDDotTl9gcYKTpLXG1+j5ChssPU5fYHGCk6S1xtAAAACHRva2VuLXYx';
  const simpleValXdr = 'AAAAFgAAAAh0b2tlbi12MQ==';
  const simpleRefJson =
      '{"executable_owner":"$ownerStrKey","tag":"token-v1"}';
  const simpleValJson = '{"executable_tag":"token-v1"}';
  const textRefXdr =
      'AAAAAcWx+fDDotTl9gcYKTpLXG1+j5ChssPU5fYHGCk6S1xtAAAAEGHDqeKCrPCfmIAJIlwKf3o=';
  const textValXdr = 'AAAAFgAAABBhw6nigqzwn5iACSJcCn96';
  const textEscapedJson = r'a\xc3\xa9\xe2\x82\xac\xf0\x9f\x98\x80\t"\\\n\x7fz';
  const textEscapedTxRep =
      r'"a\xc3\xa9\xe2\x82\xac\xf0\x9f\x98\x80\t\"\\\n\x7fz"';

  Map<String, String> txRepMap(List<String> lines) {
    final map = <String, String>{};
    for (final line in lines) {
      final idx = line.indexOf(':');
      map[line.substring(0, idx).trim()] = line.substring(idx + 1).trim();
    }
    return map;
  }

  group('executable tag XDR', () {
    test('a binary tag round trips byte for byte through the external ref', () {
      final encoded = XdrContractExecutableExternalRef(
        owner(),
        binaryTag,
      ).toBase64EncodedXdrString();
      final decoded = XdrContractExecutableExternalRef
          .fromBase64EncodedXdrString(encoded);

      expect(decoded.tag, binaryTag);
      expect(decoded.toBase64EncodedXdrString(), encoded);
    });

    test('a binary tag round trips byte for byte through XdrSCVal', () {
      final encoded = XdrSCVal.forExecutableTagBytes(
        binaryTag,
      ).toBase64EncodedXdrString();
      final decoded = XdrSCVal.fromBase64EncodedXdrString(encoded);

      expect(decoded.discriminant, XdrSCValType.SCV_EXECUTABLE_TAG);
      expect(decoded.executableTag, binaryTag);
      expect(decoded.toBase64EncodedXdrString(), encoded);
    });

    test('an ASCII tag encodes to the bytes it always has', () {
      expect(
        XdrContractExecutableExternalRef(
          owner(),
          Uint8List.fromList(utf8.encode('token-v1')),
        ).toBase64EncodedXdrString(),
        simpleRefXdr,
      );
      expect(
        XdrSCVal.forExecutableTag('token-v1').toBase64EncodedXdrString(),
        simpleValXdr,
      );
    });

    test('a multi-byte text tag encodes to the bytes it always has', () {
      expect(
        XdrContractExecutableExternalRef(
          owner(),
          textTagBytes,
        ).toBase64EncodedXdrString(),
        textRefXdr,
      );
      expect(
        XdrSCVal.forExecutableTag(textTag).toBase64EncodedXdrString(),
        textValXdr,
      );
    });

    test('a tag longer than 65535 bytes round trips', () {
      final longTag = Uint8List.fromList(
        List<int>.filled(70000, 0x41)..[69999] = 0xFF,
      );

      final refEncoded = XdrContractExecutableExternalRef(
        owner(),
        longTag,
      ).toBase64EncodedXdrString();
      final refDecoded = XdrContractExecutableExternalRef
          .fromBase64EncodedXdrString(refEncoded);
      expect(refDecoded.tag, longTag);

      final valEncoded = XdrSCVal.forExecutableTagBytes(
        longTag,
      ).toBase64EncodedXdrString();
      final valDecoded = XdrSCVal.fromBase64EncodedXdrString(valEncoded);
      expect(valDecoded.executableTag, longTag);
    });
  });

  group('executable tag text getters', () {
    test('report the text a tag spells', () {
      expect(
        XdrContractExecutableExternalRef(owner(), textTagBytes).tagString,
        textTag,
      );
      expect(
        XdrSCVal.forExecutableTag(textTag).executableTagString,
        textTag,
      );
    });

    test('throw for a tag that spells no text', () {
      expect(
        () => XdrContractExecutableExternalRef(owner(), binaryTag).tagString,
        throwsFormatException,
      );
      expect(
        () => XdrSCVal.forExecutableTagBytes(binaryTag).executableTagString,
        throwsFormatException,
      );
    });

    test('report null for an SCVal holding no executable tag', () {
      expect(XdrSCVal.forU32(7).executableTagString, isNull);
    });
  });

  group('executable tag SEP-0051 rendering', () {
    test('an ASCII tag renders as the document it always has', () {
      expect(
        XdrContractExecutableExternalRef(
          owner(),
          Uint8List.fromList(utf8.encode('token-v1')),
        ).toXdrJson(),
        simpleRefJson,
      );
      expect(XdrSCVal.forExecutableTag('token-v1').toXdrJson(), simpleValJson);
    });

    test('a multi-byte text tag renders through the escape ladder it always '
        'has', () {
      final ref = XdrContractExecutableExternalRef(owner(), textTagBytes);
      expect(
        (ref.toXdrJsonValue() as Map<String, Object?>)['tag'],
        textEscapedJson,
      );
      final val = XdrSCVal.forExecutableTag(textTag);
      expect(
        (val.toXdrJsonValue() as Map<String, Object?>)['executable_tag'],
        textEscapedJson,
      );
    });

    test('a binary tag round trips through the rendering', () {
      final ref = XdrContractExecutableExternalRef(owner(), binaryTag);
      expect(
        (ref.toXdrJsonValue() as Map<String, Object?>)['tag'],
        r'\xc0\0\xff\xfe',
      );
      expect(
        XdrContractExecutableExternalRef.fromXdrJson(ref.toXdrJson()).tag,
        binaryTag,
      );

      final val = XdrSCVal.forExecutableTagBytes(binaryTag);
      expect(
        (val.toXdrJsonValue() as Map<String, Object?>)['executable_tag'],
        r'\xc0\0\xff\xfe',
      );
      expect(
        XdrSCVal.fromXdrJson(val.toXdrJson()).executableTag,
        binaryTag,
      );
    });
  });

  group('executable tag TxRep rendering', () {
    test('an ASCII tag renders as the line it always has', () {
      final refLines = <String>[];
      XdrContractExecutableExternalRef(
        owner(),
        Uint8List.fromList(utf8.encode('token-v1')),
      ).toTxRep('tx', refLines);
      expect(refLines, contains('tx.tag: "token-v1"'));

      final valLines = <String>[];
      XdrSCVal.forExecutableTag('token-v1').toTxRep('tx', valLines);
      expect(valLines, contains('tx.executable_tag: "token-v1"'));
    });

    test('a multi-byte text tag renders as the line it always has', () {
      final refLines = <String>[];
      XdrContractExecutableExternalRef(
        owner(),
        textTagBytes,
      ).toTxRep('tx', refLines);
      expect(refLines, contains('tx.tag: $textEscapedTxRep'));

      final valLines = <String>[];
      XdrSCVal.forExecutableTag(textTag).toTxRep('tx', valLines);
      expect(valLines, contains('tx.executable_tag: $textEscapedTxRep'));
    });

    test('a binary tag round trips through the rendering', () {
      final refLines = <String>[];
      XdrContractExecutableExternalRef(
        owner(),
        binaryTag,
      ).toTxRep('tx', refLines);
      expect(refLines, contains(r'tx.tag: "\xc0\x00\xff\xfe"'));
      expect(
        XdrContractExecutableExternalRef.fromTxRep(txRepMap(refLines), 'tx').tag,
        binaryTag,
      );

      final valLines = <String>[];
      XdrSCVal.forExecutableTagBytes(binaryTag).toTxRep('tx', valLines);
      expect(valLines, contains(r'tx.executable_tag: "\xc0\x00\xff\xfe"'));
      expect(
        XdrSCVal.fromTxRep(txRepMap(valLines), 'tx').executableTag,
        binaryTag,
      );
    });
  });

  group('executable tag ledger key resolution', () {
    test('a binary tag read off an instance builds the key of its own entry',
        () {
      final directKey = XdrLedgerKey.forContractData(
        owner(),
        XdrSCVal.forExecutableTagBytes(binaryTag),
        XdrContractDataDurability.PERSISTENT,
      ).toBase64EncodedXdrString();

      final instance = XdrSCVal.forContractInstance(
        XdrSCContractInstance(
          XdrContractExecutable.forExternalRefBytes(owner(), binaryTag),
          null,
        ),
      ).toBase64EncodedXdrString();
      final ref = XdrSCVal.fromBase64EncodedXdrString(
        instance,
      ).instance!.executable.externalRef!;

      expect(ref.tag, binaryTag);
      expect(
        XdrLedgerKey.forContractData(
          ref.executableOwner,
          XdrSCVal.forExecutableTagBytes(ref.tag),
          XdrContractDataDurability.PERSISTENT,
        ).toBase64EncodedXdrString(),
        directKey,
      );
    });
  });

  group('bytes and text escapes agree', () {
    test('a signed hex escape is not an escape', () {
      // int.tryParse reads a sign, but a negative parse result names no byte,
      // so the sequence stays literal text.
      expect(
        TxRepHelper.unescapeBytes(r'"\x-1"'),
        Uint8List.fromList(utf8.encode(r'\x-1')),
      );
    });

    test('a carriage return takes its short escape both ways', () {
      final bytes = Uint8List.fromList([0x61, 0x0D, 0x62]);
      expect(TxRepHelper.escapeBytes(bytes), r'"a\rb"');
      expect(TxRepHelper.unescapeBytes(r'"a\rb"'), bytes);
    });

    test('an unknown or truncated escape stays literal text', () {
      expect(
        TxRepHelper.unescapeBytes(r'"\q"'),
        Uint8List.fromList(utf8.encode(r'\q')),
      );
      expect(
        TxRepHelper.unescapeBytes(r'"\x"'),
        Uint8List.fromList(utf8.encode(r'\x')),
      );
    });

    test('TxRepHelper escapes bytes as it escapes the text they spell', () {
      for (final text in <String>[
        '',
        'token-v1',
        textTag,
        'line\nbreak\ttab',
        r'back\slash and "quote"',
      ]) {
        final bytes = Uint8List.fromList(utf8.encode(text));
        expect(
          TxRepHelper.escapeBytes(bytes),
          TxRepHelper.escapeString(text),
          reason: 'escapeBytes disagrees with escapeString for $text',
        );
        expect(TxRepHelper.unescapeBytes(TxRepHelper.escapeBytes(bytes)), bytes);
      }
    });
  });

  group('executable tag in authorized invocations', () {
    final salt = XdrUint256(
      Uint8List.fromList(List<int>.generate(32, (i) => i)),
    );

    XdrContractIDPreimage idPreimage() {
      final preimage = XdrContractIDPreimage(
        XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS,
      );
      preimage.address = owner();
      preimage.salt = salt;
      return preimage;
    }

    test('a V1 create-contract authorization preserves a binary tag', () {
      final invocation = SorobanAuthorizedInvocation(
        SorobanAuthorizedFunction.forCreateContractHostFunction(
          XdrCreateContractArgs(
            idPreimage(),
            XdrContractExecutable.forExternalRefBytes(owner(), binaryTag),
          ),
        ),
      );

      final encoded = invocation.toXdr().toBase64EncodedXdrString();
      final restored = SorobanAuthorizedInvocation.fromXdr(
        XdrSorobanAuthorizedInvocation.fromBase64EncodedXdrString(encoded),
      );

      final args = restored.function.createContractHostFn!;
      final ref = args.executable.externalRef!;
      expect(
        Util.bytesToHex(ref.executableOwner.contractId!.hash),
        ownerContractIdHex,
      );
      expect(ref.tag, binaryTag);
      expect(args.contractIDPreimage.salt!.uint256, salt.uint256);
      expect(restored.toXdr().toBase64EncodedXdrString(), encoded);
    });

    test('a V2 create-contract authorization preserves a binary tag and its '
        'constructor args', () {
      final invocation = SorobanAuthorizedInvocation(
        SorobanAuthorizedFunction.forCreateContractV2HostFunction(
          XdrCreateContractArgsV2(
            idPreimage(),
            XdrContractExecutable.forExternalRefBytes(owner(), binaryTag),
            <XdrSCVal>[XdrSCVal.forU32(7), XdrSCVal.forBytes(binaryTag)],
          ),
        ),
      );

      final encoded = invocation.toXdr().toBase64EncodedXdrString();
      final restored = SorobanAuthorizedInvocation.fromXdr(
        XdrSorobanAuthorizedInvocation.fromBase64EncodedXdrString(encoded),
      );

      final args = restored.function.createContractV2HostFn!;
      final ref = args.executable.externalRef!;
      expect(
        Util.bytesToHex(ref.executableOwner.contractId!.hash),
        ownerContractIdHex,
      );
      expect(ref.tag, binaryTag);
      expect(args.contractIDPreimage.salt!.uint256, salt.uint256);
      expect(args.constructorArgs, hasLength(2));
      expect(args.constructorArgs[0].u32!.uint32, 7);
      expect(args.constructorArgs[1].bytes!.sCBytes, binaryTag);
      expect(restored.toXdr().toBase64EncodedXdrString(), encoded);
    });
  });
}
