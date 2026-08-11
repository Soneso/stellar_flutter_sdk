import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Renderings taken from the XDR-JSON reference implementation named by
/// SEP-0051, driven at the version this SDK is written against.
///
/// Each case pins the exact document the reference produces for a known binary
/// value, so the assertions anchor to the specification's own output rather
/// than to this SDK's inverse. A round trip alone would pass even if both
/// directions were wrong in the same way.
///
/// The types here are the ones whose rendering is not implied by their XDR
/// shape: a contract identifier and a liquidity pool identifier are strkeys
/// rather than hexadecimal, and an asset code carries NUL padding that is not
/// part of its value.
void main() {
  group('XDR-JSON matches the reference rendering', () {
    test('renders a contract identifier as a strkey beside a plain hash', () {
      // Both fields are a 32-byte hash in Dart; only the declared XDR type
      // tells them apart.
      final XdrConfigUpgradeSetKey key =
          XdrConfigUpgradeSetKey.fromBase64EncodedXdrString(
            'AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEC'
            'AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg==',
          );
      expect(
        key.toXdrJson(),
        '{"contract_id":'
        '"CAAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQC526",'
        '"content_hash":'
        '"0202020202020202020202020202020202020202020202020202020202020202"}',
      );
    });

    test('renders a liquidity pool identifier as a strkey', () {
      final XdrLiquidityPoolWithdrawOp op =
          XdrLiquidityPoolWithdrawOp.fromBase64EncodedXdrString(
            'AwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMA'
            'AAAAAAAAZAAAAAAAAAABAAAAAAAAAAI=',
          );
      expect(
        op.toXdrJson(),
        '{"liquidity_pool_id":'
        '"LABQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQG3AW",'
        '"amount":"100","min_amount_a":"1","min_amount_b":"2"}',
      );
    });

    test('renders a pool share trustline asset as a bare strkey arm', () {
      const String json =
          '{"pool_share":'
          '"LADQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQPEA4"}';
      expect(XdrTrustlineAsset.fromXdrJson(json).toXdrJson(), json);
    });

    test('drops the NUL padding of a four-byte asset code', () {
      final XdrAssetAlphaNum4 asset =
          XdrAssetAlphaNum4.fromBase64EncodedXdrString(
            'VVNEAAAAAAAJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQ==',
          );
      expect(asset.toXdrJsonValue(), isA<Map<String, Object?>>());
      expect(
        (asset.toXdrJsonValue()! as Map<String, Object?>)['asset_code'],
        'USD',
      );
    });

    test('pads a twelve-byte asset code back to five bytes', () {
      final XdrAssetAlphaNum12 asset =
          XdrAssetAlphaNum12.fromBase64EncodedXdrString(
            'VVMAAAAAAAAAAAAAAAAAAAkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJ',
          );
      expect(
        (asset.toXdrJsonValue()! as Map<String, Object?>)['asset_code'],
        r'US\0\0\0',
      );
    });

    test('renders an all-NUL twelve-byte asset code as five escaped NULs', () {
      final XdrAssetAlphaNum12 asset =
          XdrAssetAlphaNum12.fromBase64EncodedXdrString(
            'AAAAAAAAAAAAAAAAAAAAAAkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJ',
          );
      expect(
        (asset.toXdrJsonValue()! as Map<String, Object?>)['asset_code'],
        r'\0\0\0\0\0',
      );
    });

    test('renders an all-NUL four-byte asset code as the empty string', () {
      final XdrAssetAlphaNum4 asset =
          XdrAssetAlphaNum4.fromBase64EncodedXdrString(
            'AAAAAAAAAAAJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQ==',
          );
      expect(
        (asset.toXdrJsonValue()! as Map<String, Object?>)['asset_code'],
        '',
      );
    });

    test('renders an account identifier as a G-strkey', () {
      const String json =
          '"GACQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKG7N"';
      const String base64 = 'AAAAAAUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUF';
      expect(XdrPublicKey.fromXdrJson(json).toXdrJson(), json);
      expect(XdrPublicKey.fromXdrJson(json).toBase64EncodedXdrString(), base64);
    });

    test('renders both arms of a muxed account', () {
      const String ed25519 =
          '"GACQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKG7N"';
      const String med25519 =
          '"MADQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOAAAAAAAAAAAFKY6G"';
      expect(XdrMuxedAccount.fromXdrJson(ed25519).toXdrJson(), ed25519);
      expect(
        XdrMuxedAccount.fromXdrJson(ed25519).toBase64EncodedXdrString(),
        'AAAAAAUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUF',
      );
      expect(XdrMuxedAccount.fromXdrJson(med25519).toXdrJson(), med25519);
      expect(
        XdrMuxedAccount.fromXdrJson(med25519).toBase64EncodedXdrString(),
        'AAABAAAAAAAAAAAqBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwc=',
      );
    });

    test('renders a muxed account payload as an M-strkey on its own', () {
      // The .x declares this twice, as MuxedEd25519Account and as MuxedAccount's
      // med25519 arm; one Dart class serves both, and the rendering above shows
      // the two agree on the wire.
      const String json =
          '"MADQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOAAAAAAAAAAAFKY6G"';
      expect(XdrMuxedAccountMed25519.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrMuxedAccountMed25519.fromXdrJson(json).toBase64EncodedXdrString(),
        'AAAAAAAAACoHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBw==',
      );
    });

    test('renders every arm of a contract address by its strkey kind', () {
      const Map<String, String> arms = <String, String>{
        '"GACQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKG7N"':
            'AAAAAAAAAAAFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQ==',
        '"CADAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMSST"':
            'AAAAAQYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYG',
        '"MADQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOAAAAAAAAAAAFKY6G"':
            'AAAAAgAAAAAAAAAqBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwc=',
        '"BAAAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBROVY"':
            'AAAAAwAAAAAGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBg==',
        '"LADAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMLY6"':
            'AAAABAYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYG',
      };
      arms.forEach((String json, String base64) {
        expect(XdrSCAddress.fromXdrJson(json).toXdrJson(), json);
        expect(
          XdrSCAddress.fromXdrJson(json).toBase64EncodedXdrString(),
          base64,
        );
      });
    });

    test('renders every arm of a signer key by its strkey kind', () {
      const Map<String, String> arms = <String, String>{
        '"GACQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKG7N"':
            'AAAAAAUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUF',
        '"TACQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQL3N4"':
            'AAAAAQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUF',
        '"XACQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQK7IF"':
            'AAAAAgUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUF',
        '"PACQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKAAAAAB2VO6MAA4AC"':
            'AAAAAwUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFAAAAA6q7zAA=',
      };
      arms.forEach((String json, String base64) {
        expect(XdrSignerKey.fromXdrJson(json).toXdrJson(), json);
        expect(
          XdrSignerKey.fromXdrJson(json).toBase64EncodedXdrString(),
          base64,
        );
      });
    });

    test('renders a signed payload as a P-strkey', () {
      // The payload is three bytes, so the region carries a NUL pad byte that
      // the rendering has to account for and the reader has to reject if it is
      // not NUL.
      const String json =
          '"PACQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKBIFAUCQKAAAAAB2VO6MAA4AC"';
      expect(XdrSignedPayload.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrSignedPayload.fromXdrJson(json).toBase64EncodedXdrString(),
        'BQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUAAAADqrvMAA==',
      );
    });

    test('renders a claimable balance identifier as a B-strkey', () {
      const String json =
          '"BAAAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBROVY"';
      expect(XdrClaimableBalanceID.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrClaimableBalanceID.fromXdrJson(json).toBase64EncodedXdrString(),
        'AAAAAAYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYG',
      );
    });

    test('renders an asset code union as a bare string, not a keyed arm', () {
      // The union carries no arm key on the wire: its two arms are told apart
      // by the width of the rendered code alone.
      const Map<String, String> codes = <String, String>{
        r'"USD"': 'AAAAAVVTRAA=',
        r'""': 'AAAAAQAAAAA=',
        r'"US\\0\\0\\0"': 'AAAAAlVTAAAAAAAAAAAAAA==',
        r'"\\0\\0\\0\\0\\0"': 'AAAAAgAAAAAAAAAAAAAAAA==',
      };
      codes.forEach((String json, String base64) {
        expect(XdrAllowTrustOpAsset.fromXdrJson(json).toXdrJson(), json);
        expect(
          XdrAllowTrustOpAsset.fromXdrJson(json).toBase64EncodedXdrString(),
          base64,
        );
      });
    });

    test('picks the asset code arm by rendered width', () {
      // Four characters is the widest an AlphaNum4 code can be and five the
      // narrowest an AlphaNum12 can be, so this pair is what a dispatch with an
      // off-by-one boundary gets wrong while every other case still passes.
      expect(
        XdrAllowTrustOpAsset.fromXdrJson(r'"ABCD"').toBase64EncodedXdrString(),
        'AAAAAUFCQ0Q=',
      );
      expect(
        XdrAllowTrustOpAsset.fromXdrJson(r'"ABCDE"').toBase64EncodedXdrString(),
        'AAAAAkFCQ0RFAAAAAAAAAA==',
      );
    });

    test('renders an asset code inside the operation that carries it', () {
      final XdrAllowTrustOp op = XdrAllowTrustOp.fromBase64EncodedXdrString(
        'AAAAAAkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJAAAAAVVTRAAAAAAB',
      );
      expect(
        op.toXdrJson(),
        '{"trustor":'
        '"GAEQSCIJBEEQSCIJBEEQSCIJBEEQSCIJBEEQSCIJBEEQSCIJBEEQSH7S",'
        '"asset":"USD","authorize":1}',
      );
    });

    test('refuses a claimable balance identifier with an unknown tag', () {
      // The strkey payload is a one-byte discriminant followed by the hash, and
      // the checksum says nothing about the discriminant. A reader that ignored
      // it would round-trip its own output and pass every positive case.
      expect(
        () => XdrClaimableBalanceID.fromXdrJson(
          '"BAAQAAICAMCAKBQHBAEQUCYMBUHA6EARCIJRIFIWC4MBSGQ3DQOR4H4P7Y"',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('renders an optional union arm as null or as its value', () {
      // An arm whose body the .x declares optional is not a void arm: the key
      // is present either way and the body behind it is null when absent. Each
      // pair below is the same arm in both states, because a rendering that
      // handles only one of the two passes half of these.
      const Map<String, String> scVal = <String, String>{
        '{"vec":null}': 'AAAAEAAAAAA=',
        '{"vec":[]}': 'AAAAEAAAAAEAAAAA',
        '{"map":null}': 'AAAAEQAAAAA=',
        '{"map":[]}': 'AAAAEQAAAAEAAAAA',
      };
      scVal.forEach((String json, String base64) {
        expect(XdrSCVal.fromXdrJson(json).toXdrJson(), json);
        expect(XdrSCVal.fromXdrJson(json).toBase64EncodedXdrString(), base64);
      });

      const Map<String, String> predicate = <String, String>{
        '{"not":null}': 'AAAAAwAAAAA=',
        '{"not":"unconditional"}': 'AAAAAwAAAAEAAAAA',
      };
      predicate.forEach((String json, String base64) {
        expect(XdrClaimPredicate.fromXdrJson(json).toXdrJson(), json);
        expect(
          XdrClaimPredicate.fromXdrJson(json).toBase64EncodedXdrString(),
          base64,
        );
      });
    });

    test('renders an array of optional account identifiers', () {
      // SponsorshipDescriptor is `AccountID*`, so an element of
      // signerSponsoringIDs is a strkey or null and its binary form carries a
      // presence flag either way. Each pair is the reference's rendering of the
      // base64 beside it.
      const Map<String, String> entries = <String, String>{
        '{"num_sponsored":0,"num_sponsoring":0,'
                '"signer_sponsoring_i_ds":[],"ext":"v0"}':
            'AAAAAAAAAAAAAAAAAAAAAA==',
        '{"num_sponsored":0,"num_sponsoring":1,'
                '"signer_sponsoring_i_ds":[null],"ext":"v0"}':
            'AAAAAAAAAAEAAAABAAAAAAAAAAA=',
        '{"num_sponsored":0,"num_sponsoring":1,"signer_sponsoring_i_ds":'
                '["GAAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQDZ7H"],'
                '"ext":"v0"}':
            'AAAAAAAAAAEAAAABAAAAAQAAAAABAQEBAQEBAQEBAQEBAQEBAQEBAQEB'
            'AQEBAQEBAQEBAQAAAAA=',
        '{"num_sponsored":2,"num_sponsoring":3,"signer_sponsoring_i_ds":'
                '["GAAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQDZ7H",'
                'null,'
                '"GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H"],'
                '"ext":"v0"}':
            'AAAAAgAAAAMAAAADAAAAAQAAAAABAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB'
            'AQEBAQAAAAAAAAABAAAAAGL8HQvQkbK2HA3WVjRrKmjX00fG8sLI7m0ERwJW'
            '/AX3AAAAAA==',
      };
      entries.forEach((String json, String base64) {
        expect(
          XdrAccountEntryV2.fromBase64EncodedXdrString(base64).toXdrJson(),
          json,
        );
        expect(
          XdrAccountEntryV2.fromXdrJson(json).toBase64EncodedXdrString(),
          base64,
        );
      });
    });

    test('renders an optional field of a struct nested in a union case', () {
      // This one reaches the struct path rather than the arm path, so it is
      // what shows the two agree on the same rendering.
      const Map<String, String> components = <String, String>{
        '{"txset_comp_txs_maybe_discounted_fee":{"base_fee":null,"txs":[]}}':
            'AAAAAAAAAAAAAAAA',
        '{"txset_comp_txs_maybe_discounted_fee":{"base_fee":"100","txs":[]}}':
            'AAAAAAAAAAEAAAAAAAAAZAAAAAA=',
      };
      components.forEach((String json, String base64) {
        expect(XdrTxSetComponent.fromXdrJson(json).toXdrJson(), json);
        expect(
          XdrTxSetComponent.fromXdrJson(json).toBase64EncodedXdrString(),
          base64,
        );
      });
    });

    test('crosses to the binary codec after parsing', () {
      // A JSON round trip cannot see a disagreement between the two decoders
      // about the in-memory value, so the parsed document is re-encoded as XDR
      // and compared with the binary form it came from.
      const String base64 =
          'AwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMA'
          'AAAAAAAAZAAAAAAAAAABAAAAAAAAAAI=';
      final String json = XdrLiquidityPoolWithdrawOp.fromBase64EncodedXdrString(
        base64,
      ).toXdrJson();
      expect(
        XdrLiquidityPoolWithdrawOp.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });
  });
}
