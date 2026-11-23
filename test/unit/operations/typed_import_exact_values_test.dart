// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final String _account = KeyPair.random().accountId;

/// Returns the base64 of a V1 envelope holding [operation], after [patch] has
/// set one raw field of the decoded operation body.
String _envelope(
  Operation operation, [
  void Function(XdrOperationBody)? patch,
]) {
  final XdrTransactionEnvelope envelope =
      XdrTransactionEnvelope.fromBase64EncodedXdrString(
        TransactionBuilder(
          Account(_account, BigInt.one),
        ).addOperation(operation).build().toEnvelopeXdrBase64(),
      );
  patch?.call(envelope.v1!.tx.operations.first.body);
  return envelope.toBase64EncodedXdrString();
}

XdrOperationBody _raw(String envelope) =>
    XdrTransactionEnvelope.fromBase64EncodedXdrString(
      envelope,
    ).v1!.tx.operations.first.body;

void _expectRoundTrip(String envelope) => expect(
  AbstractTransaction.fromEnvelopeXdrString(envelope).toEnvelopeXdrBase64(),
  equals(envelope),
);

Matcher _rangeError(int value) => throwsA(
  isA<RangeError>().having(
    (RangeError error) => error.invalidValue,
    'invalidValue',
    value,
  ),
);

Matcher _formatError(String named) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(named)),
);

void _expectRefused(String envelope, String named) => expect(
  () => AbstractTransaction.fromEnvelopeXdrString(envelope),
  _formatError(named),
);

/// [ascii] followed by [extra] and zero bytes up to [width].
Uint8List _code(String ascii, int width, [List<int> extra = const []]) =>
    Uint8List(width)..setAll(0, [...ascii.codeUnits, ...extra]);

/// Code bytes of [width] that hold the byte 0xE9.
Uint8List _e9(int width) =>
    width == 4 ? _code('', 4, [0xE9]) : _code('ABCDE', 12, [0xE9]);

/// A credit asset of the arm that [width] selects.
Asset _credit(int width) => width == 4
    ? AssetTypeCreditAlphaNum4('AAA', _account)
    : AssetTypeCreditAlphaNum12('BBBBB', _account);

/// Writes [code] into the credit arm of its width.
void _setCode(XdrAssetAlphaNum4? a4, XdrAssetAlphaNum12? a12, Uint8List code) =>
    code.length == 4 ? a4!.assetCode = code : a12!.assetCode = code;

Uint8List _rawCode(XdrAssetAlphaNum4? a4, XdrAssetAlphaNum12? a12) =>
    a4?.assetCode ?? a12!.assetCode;

/// A change trust operation for a pool share of two credit assets.
Operation _poolTrust() => ChangeTrustOperationBuilder(
  AssetTypePoolShare(assetA: _credit(4), assetB: _credit(12)),
  '1',
).build();

XdrLiquidityPoolConstantProductParameters _pool(XdrOperationBody body) =>
    body.changeTrustOp!.line.liquidityPool!.constantProduct!;

void main() {
  group('signer weight', () {
    final XdrSignerKey key = SignerKey.ed25519PublicKey(KeyPair.random());
    String withWeight(int weight) => _envelope(
      SetOptionsOperationBuilder().setSigner(key, 1).build(),
      (body) => body.setOptionsOp!.signer!.weight = XdrUint32(weight),
    );
    int rawWeight(String input) =>
        _raw(input).setOptionsOp!.signer!.weight.uint32;

    for (final int weight in [256, 0xFFFFFFFF]) {
      test('import keeps weight $weight, the envelope and the hash', () {
        final String input = withWeight(weight);
        expect(rawWeight(input), weight);
        final Transaction typed =
            AbstractTransaction.fromEnvelopeXdrString(input) as Transaction;
        expect(typed.toEnvelopeXdrBase64(), equals(input));
        final Operation operation = typed.operations.first;
        expect((operation as SetOptionsOperation).signerWeight, weight);
        final XdrDataOutputStream base = XdrDataOutputStream();
        base.write(Network.TESTNET.networkId);
        base.writeInt(XdrEnvelopeType.ENVELOPE_TYPE_TX.value);
        XdrTransaction.encode(
          base,
          XdrTransactionEnvelope.fromBase64EncodedXdrString(input).v1!.tx,
        );
        final List<int> expected = sha256.convert(base.bytes).bytes;
        expect(typed.hash(Network.TESTNET), equals(expected));
      });
    }

    for (final int weight in [0, 1, 255]) {
      test('import round trips weight $weight', () {
        final String input = withWeight(weight);
        expect(rawWeight(input), weight);
        _expectRoundTrip(input);
      });
    }

    for (final int weight in [-1, 0x100000000]) {
      test('setSigner refuses weight $weight', () {
        final builder = SetOptionsOperationBuilder();
        expect(() => builder.setSigner(key, weight), _rangeError(weight));
      });

      test('encoding refuses constructor weight $weight', () {
        final SetOptionsOperation operation = SetOptionsOperation(
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          key,
          weight,
        );
        expect(() => operation.toOperationBody(), _rangeError(weight));
      });
    }
  });

  group('liquidity pool fee', () {
    String withFee(int fee) =>
        _envelope(_poolTrust(), (body) => _pool(body).fee = XdrInt32(fee));

    for (final int fee in [0, 29, 31]) {
      test('import refuses fee $fee', () {
        final String input = withFee(fee);
        expect(_pool(_raw(input)).fee.int32, fee);
        _expectRefused(input, 'fee $fee ');
        final XdrChangeTrustAsset line = _raw(input).changeTrustOp!.line;
        expect(
          () => Asset.fromXdrChangeTrustAsset(line),
          _formatError('fee $fee '),
        );
      });
    }

    test('import round trips fee 30', () {
      final String input = withFee(30);
      expect(_pool(_raw(input)).fee.int32, 30);
      _expectRoundTrip(input);
    });
  });

  group('allow trust', () {
    final String trustor = KeyPair.random().accountId;
    String allowTrust(String code, [void Function(XdrAllowTrustOp)? patch]) =>
        _envelope(
          AllowTrustOperationBuilder(trustor, code, 1).build(),
          (body) => patch?.call(body.allowTrustOp!),
        );
    String withAuthorize(int value) =>
        allowTrust('ABC', (op) => op.authorize = value);
    XdrAllowTrustOpAsset rawAsset(String input) =>
        _raw(input).allowTrustOp!.asset;

    for (final int authorize in [3, 0x7FFFFFFF]) {
      test('import refuses authorize $authorize', () {
        final String input = withAuthorize(authorize);
        expect(_raw(input).allowTrustOp!.authorize, authorize);
        _expectRefused(input, 'value $authorize ');
      });
    }

    test('builder refuses an XdrAllowTrustOp with authorize 0xFFFFFFFF', () {
      final XdrAllowTrustOp raw = _raw(allowTrust('ABC')).allowTrustOp!;
      final op = XdrAllowTrustOp(raw.trustor, raw.asset, 0xFFFFFFFF);
      final String named = 'value 4294967295 ';
      expect(() => AllowTrustOperation.builder(op), _formatError(named));
    });

    test('AllowTrustOperationBuilder refuses authorize 3', () {
      final builder = () => AllowTrustOperationBuilder(trustor, 'ABC', 3);
      expect(builder, _rangeError(3));
    });

    for (final int authorize in [0, 1, 2]) {
      test('import round trips authorize $authorize', () {
        final String input = withAuthorize(authorize);
        expect(_raw(input).allowTrustOp!.authorize, authorize);
        _expectRoundTrip(input);
      });
    }

    for (final String code in ['', 'A', 'ABCD']) {
      test('import refuses an ALPHANUM12 code of ${code.length} bytes', () {
        final Uint8List bytes = _code(code, 12);
        final input = allowTrust('ABCDE', (op) => op.asset.assetCode12 = bytes);
        expect(
          rawAsset(input).discriminant,
          XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
        );
        expect(rawAsset(input).assetCode12, equals(bytes));
        _expectRefused(input, '"$code"');
      });
    }

    for (final String code in ['ABCD', 'ABCDE', 'ABCDEFGHIJKL']) {
      test('import round trips the code $code in its arm', () {
        final String input = allowTrust(code);
        final int width = code.length <= 4 ? 4 : 12;
        final XdrAllowTrustOpAsset asset = rawAsset(input);
        expect(
          asset.discriminant,
          width == 4
              ? XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4
              : XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
        );
        expect(asset.assetCode4 ?? asset.assetCode12, _code(code, width));
        _expectRoundTrip(input);
      });
    }

    for (final int width in [4, 12]) {
      final Uint8List bytes = _e9(width);
      test('import refuses the code bytes ${Util.bytesToHex(bytes)}', () {
        final input = allowTrust(width == 4 ? 'A' : 'ABCDE', (op) {
          width == 4
              ? op.asset.assetCode4 = bytes
              : op.asset.assetCode12 = bytes;
        });
        final XdrAllowTrustOpAsset asset = rawAsset(input);
        expect(asset.assetCode4 ?? asset.assetCode12, equals(bytes));
        _expectRefused(input, Util.bytesToHex(bytes));
      });
    }
  });

  group('asset code bytes', () {
    String payment(Asset asset, [Uint8List? code]) => _envelope(
      PaymentOperationBuilder(_account, asset, '1').build(),
      (body) {
        final XdrAsset a = body.paymentOp!.asset;
        if (code != null) _setCode(a.alphaNum4, a.alphaNum12, code);
      },
    );
    Uint8List paymentCode(String input) {
      final XdrAsset asset = _raw(input).paymentOp!.asset;
      return _rawCode(asset.alphaNum4, asset.alphaNum12);
    }

    final List<Uint8List> refused = [
      _e9(4),
      _e9(12),
      _code('A', 4, [0x80]),
      _code('A', 4, [0x00, 0xE9]),
    ];
    for (final Uint8List bytes in refused) {
      final String hex = Util.bytesToHex(bytes);
      test('payment import refuses the code bytes $hex', () {
        final String input = payment(_credit(bytes.length), bytes);
        expect(paymentCode(input), equals(bytes));
        _expectRefused(input, hex);
      });
    }

    for (final int width in [4, 12]) {
      final String hex = Util.bytesToHex(_e9(width));
      test('change trust import refuses the code bytes $hex', () {
        final String input = _envelope(
          ChangeTrustOperationBuilder(_credit(width), '1').build(),
          (body) {
            final XdrChangeTrustAsset line = body.changeTrustOp!.line;
            _setCode(line.alphaNum4, line.alphaNum12, _e9(width));
          },
        );
        final XdrChangeTrustAsset line = _raw(input).changeTrustOp!.line;
        expect(_rawCode(line.alphaNum4, line.alphaNum12), equals(_e9(width)));
        _expectRefused(input, hex);
      });
    }

    for (final int width in [4, 12]) {
      final String side = width == 4 ? 'A' : 'B';
      final String hex = Util.bytesToHex(_e9(width));
      test('pool share import refuses asset $side with code bytes $hex', () {
        XdrAsset poolAsset(XdrOperationBody body) =>
            width == 4 ? _pool(body).assetA : _pool(body).assetB;
        final String input = _envelope(_poolTrust(), (body) {
          final XdrAsset a = poolAsset(body);
          _setCode(a.alphaNum4, a.alphaNum12, _e9(width));
        });
        final XdrAsset raw = poolAsset(_raw(input));
        expect(_rawCode(raw.alphaNum4, raw.alphaNum12), equals(_e9(width)));
        _expectRefused(input, hex);
      });
    }

    test('payment import keeps the code bytes 417f0000', () {
      final Uint8List bytes = _code('A', 4, [0x7F]);
      final String input = payment(_credit(4), bytes);
      expect(paymentCode(input), equals(bytes));
      _expectRoundTrip(input);
    });

    for (final String code in ['A', 'ABCD', 'ABCDE', 'ABCDEFGHIJKL']) {
      test('payment import round trips the code $code', () {
        final int width = code.length <= 4 ? 4 : 12;
        final String input = payment(
          width == 4
              ? AssetTypeCreditAlphaNum4(code, _account)
              : AssetTypeCreditAlphaNum12(code, _account),
        );
        expect(paymentCode(input), equals(_code(code, width)));
        _expectRoundTrip(input);
      });
    }
  });
}
