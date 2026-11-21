// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// The XDR strings the SDK stores as bytes (memo text, SCVal string and
// symbol, contract function name) and the strict UTF-8 view every XDR string
// is read through. Runs on the VM and with --platform chrome.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/xdr/txrep_helper.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Uint8List _hex(String hex) => Util.hexToBytes(hex);

Uint8List _encodeSCVal(XdrSCVal value) {
  final XdrDataOutputStream stream = XdrDataOutputStream();
  XdrSCVal.encode(stream, value);
  return Uint8List.fromList(stream.bytes);
}

const String _contract =
    'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';
const String _account =
    'GB6XJIMOUTHNC6KYHWTOECKQJY2UHCFRODONBGMNKG5KVBB5PZHTB5XB';

void main() {
  group('XdrUtf8', () {
    test('keeps every leading byte order mark', () {
      expect(XdrUtf8.decode(_hex('efbbbf61')), '\uFEFFa');
      expect(XdrUtf8.decode(_hex('efbbbfefbbbf61')), '\uFEFF\uFEFFa');
      expect(XdrUtf8.decode(_hex('efbbbf')), '\uFEFF');
      expect(XdrUtf8.decode(_hex('61efbbbf')), 'a\uFEFF');
      expect(XdrUtf8.decode(_hex('c3a931')), 'é1');
      expect(XdrUtf8.decode(Uint8List(0)), '');
    });

    test('refuses bytes that are not valid UTF-8', () {
      for (final String bad in <String>['ff', 'c3', 'fffe20616263', 'c080']) {
        expect(() => XdrUtf8.decode(_hex(bad)), throwsFormatException);
        expect(XdrUtf8.tryDecode(_hex(bad)), isNull);
      }
      expect(XdrUtf8.tryDecode(_hex('efbbbf61')), '\uFEFFa');
    });

    test('encodes text back to the bytes it was read from', () {
      for (final String hex in <String>[
        'efbbbf61',
        'efbbbfefbbbf61',
        'c3a931',
      ]) {
        expect(XdrUtf8.encode(XdrUtf8.decode(_hex(hex))), _hex(hex));
      }
    });
  });

  group('strict views of the other XDR strings', () {
    test('readString keeps the byte order mark', () {
      final XdrSCMetaV0 meta = XdrSCMetaV0.decode(
        XdrDataInputStream(_hex('000000036b65790000000004efbbbf61')),
      );
      expect(meta.key, 'key');
      expect(meta.val, '\uFEFFa');
    });

    test('TxRep and XDR-JSON text readers keep the byte order mark', () {
      expect(TxRepHelper.unescapeString(r'"\xef\xbb\xbfa"'), '\uFEFFa');
      expect(TxRepHelper.unescapeString(r'"a\xef\xbb\xbf"'), 'a\uFEFF');
      expect(
        () => TxRepHelper.unescapeString(r'"\xff"'),
        throwsFormatException,
      );
      expect(
        XdrJsonHelper.readEscapedString(r'\xef\xbb\xbfa', type: 'T'),
        '\uFEFFa',
      );
    });

    test('executable tag views keep the byte order mark', () {
      final Uint8List tag = _hex('efbbbf61');
      expect(
        XdrSCVal.forExecutableTagBytes(tag).executableTagString,
        '\uFEFFa',
      );
      final Address owner = Address.forContractId(_contract);
      expect(
        XdrContractExecutableExternalRef(owner.toXdr(), tag).tagString,
        '\uFEFFa',
      );
      final Address deployer = Address.forAccountId(_account);
      expect(
        CreateContractFromExternalRefHostFunction(
          deployer,
          owner,
          tag,
        ).tagString,
        '\uFEFFa',
      );
      expect(
        CreateContractFromExternalRefWithConstructorHostFunction(
          deployer,
          owner,
          tag,
          <XdrSCVal>[],
        ).tagString,
        '\uFEFFa',
      );
      final DeployFromExternalRefRequest request = DeployFromExternalRefRequest(
        sourceAccountKeyPair: KeyPair.random(),
        network: Network.TESTNET,
        rpcUrl: 'https://soroban-testnet.stellar.org',
        executableOwner: owner,
        tag: tag,
      );
      expect(request.tagString, '\uFEFFa');
    });
  });

  group('SCVal string and symbol', () {
    final Uint8List ffFe = _hex('fffe20616263');

    test('decode and encode keep bytes that are not UTF-8', () {
      for (final String b64 in <String>[
        'AAAADgAAAAb//iBhYmMAAA==',
        'AAAADwAAAAb//iBhYmMAAA==',
        'AAAADgAAAATvu79h',
        'AAAADwAAAATvu79h',
      ]) {
        final XdrSCVal value = XdrSCVal.fromBase64EncodedXdrString(b64);
        expect(value.toBase64EncodedXdrString(), b64);
      }
      final XdrSCVal str = XdrSCVal.fromBase64EncodedXdrString(
        'AAAADgAAAAb//iBhYmMAAA==',
      );
      expect(str.strBytes, ffFe);
      expect(() => str.str, throwsFormatException);
      final XdrSCVal sym = XdrSCVal.fromBase64EncodedXdrString(
        'AAAADwAAAATvu79h',
      );
      expect(sym.symBytes, _hex('efbbbf61'));
      expect(sym.sym, '\uFEFFa');
    });

    test('the bytes factories encode the given bytes', () {
      expect(
        XdrSCVal.forStringBytes(ffFe).toBase64EncodedXdrString(),
        'AAAADgAAAAb//iBhYmMAAA==',
      );
      expect(
        XdrSCVal.forSymbolBytes(ffFe).toBase64EncodedXdrString(),
        'AAAADwAAAAb//iBhYmMAAA==',
      );
      expect(
        () => _encodeSCVal(XdrSCVal.forSymbolBytes(Uint8List(33))),
        throwsRangeError,
      );
      expect(XdrSCVal.forString('\uFEFFa').strBytes, _hex('efbbbf61'));
    });

    test('XDR-JSON and TxRep keep the bytes', () {
      for (final String json in <String>[
        r'{"string":"\\xff\\xfe abc"}',
        r'{"symbol":"\\xff\\xfe abc"}',
        r'{"string":"\\xef\\xbb\\xbfa"}',
        r'{"symbol":"\\xef\\xbb\\xbfa"}',
      ]) {
        expect(XdrSCVal.fromXdrJson(json).toXdrJson(), json);
      }
      for (final (String arm, String type) in <(String, String)>[
        ('str', 'SCV_STRING'),
        ('sym', 'SCV_SYMBOL'),
      ]) {
        for (final String value in <String>[
          r'"\xff\xfe abc"',
          r'"\xef\xbb\xbfa"',
        ]) {
          final Map<String, String> map = <String, String>{
            'v.type': type,
            'v.$arm': value,
          };
          final XdrSCVal decoded = XdrSCVal.fromTxRep(map, 'v');
          final List<String> lines = <String>[];
          decoded.toTxRep('v', lines);
          expect(lines, <String>['v.type: $type', 'v.$arm: $value']);
        }
      }
      final XdrSCVal fromTxRep = XdrSCVal.fromTxRep(<String, String>{
        'v.type': 'SCV_SYMBOL',
        'v.sym': r'"\xff\xfe abc"',
      }, 'v');
      expect(fromTxRep.symBytes, ffFe);
      expect(
        () => XdrSCVal.fromTxRep(<String, String>{
          'v.type': 'SCV_SYMBOL',
          'v.sym': '"${'a' * 33}"',
        }, 'v'),
        throwsException,
      );
    });

    test('decoding does not alias the input buffer', () {
      final Uint8List input = _hex('0000000e00000006fffe206162630000');
      final XdrSCVal value = XdrSCVal.decode(XdrDataInputStream(input));
      input[8] = 0x00;
      expect(value.strBytes, ffFe);
    });
  });

  group('memo text', () {
    test('decode, XDR-JSON and TxRep keep the bytes', () {
      final XdrMemo memo = XdrMemo.fromXdrJson(r'{"text":"\\xff\\xfe abc"}');
      expect(memo.textBytes, _hex('fffe20616263'));
      expect(() => memo.text, throwsFormatException);
      final List<String> lines = <String>[];
      memo.toTxRep('m', lines);
      expect(lines, <String>['m.type: MEMO_TEXT', r'm.text: "\xff\xfe abc"']);
      final XdrMemo back = XdrMemo.fromTxRep(<String, String>{
        'm.type': 'MEMO_TEXT',
        'm.text': r'"\xef\xbb\xbfa"',
      }, 'm');
      expect(back.text, '\uFEFFa');
      expect(back.toXdrJson(), r'{"text":"\\xef\\xbb\\xbfa"}');
    });

    test('the declared maximum of 28 bytes holds on every path', () {
      final XdrMemo memo = XdrMemo(XdrMemoType.MEMO_TEXT)
        ..textBytes = Uint8List(29);
      expect(
        () => XdrMemo.encode(XdrDataOutputStream(), memo),
        throwsRangeError,
      );
      expect(
        () => XdrMemo.fromTxRep(<String, String>{
          'm.type': 'MEMO_TEXT',
          'm.text': '"${r'\xff' * 29}"',
        }, 'm'),
        throwsException,
      );
      final XdrMemo full = XdrMemo(XdrMemoType.MEMO_TEXT)
        ..textBytes = Uint8List.fromList(List<int>.filled(28, 0xff));
      final XdrDataOutputStream stream = XdrDataOutputStream();
      XdrMemo.encode(stream, full);
      final XdrMemo decoded = XdrMemo.decode(
        XdrDataInputStream(Uint8List.fromList(stream.bytes)),
      );
      expect(decoded.textBytes, full.textBytes);
    });
  });

  group('contract function name', () {
    final Uint8List ffFe = _hex('fffe20616263');
    final XdrSCAddress address = Address.forContractId(_contract).toXdr();

    test('the bytes constructor, XDR-JSON and TxRep keep the bytes', () {
      final XdrInvokeContractArgs args =
          XdrInvokeContractArgs.withFunctionNameBytes(
            address,
            ffFe,
            <XdrSCVal>[],
          );
      final XdrInvokeContractArgs decoded =
          XdrInvokeContractArgs.fromBase64EncodedXdrString(
            args.toBase64EncodedXdrString(),
          );
      expect(decoded.functionNameBytes, ffFe);
      expect(() => decoded.functionName, throwsFormatException);

      final String json = args.toXdrJson();
      expect(json, contains(r'"function_name":"\\xff\\xfe abc"'));
      expect(XdrInvokeContractArgs.fromXdrJson(json).functionNameBytes, ffFe);

      final List<String> lines = <String>[];
      args.toTxRep('f', lines);
      expect(lines, contains(r'f.functionName: "\xff\xfe abc"'));
      final Map<String, String> map = <String, String>{
        for (final String line in lines)
          line.substring(0, line.indexOf(': ')): line.substring(
            line.indexOf(': ') + 2,
          ),
      };
      expect(XdrInvokeContractArgs.fromTxRep(map, 'f').functionNameBytes, ffFe);
    });

    test('the String constructor and setter store the UTF-8 encoding', () {
      final XdrInvokeContractArgs args = XdrInvokeContractArgs(
        address,
        '\uFEFFhello',
        <XdrSCVal>[],
      );
      expect(args.functionNameBytes, _hex('efbbbf68656c6c6f'));
      args.functionName = 'transfer';
      expect(args.functionNameBytes, _hex('7472616e73666572'));
      args.functionNameBytes = ffFe;
      expect(args.functionNameBytes, ffFe);
    });
  });
}
