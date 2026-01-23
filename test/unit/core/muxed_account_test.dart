import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('MuxedAccount', () {
    final testAccountId = 'GAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSTVY';
    final testMuxedAccountId = 'MAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSAAAAAAAAAAE2LP26';
    final testMuxedId = BigInt.from(1234);

    group('MuxedAccount creation', () {
      test('creates MuxedAccount from G account ID without ID', () {
        final account = MuxedAccount(testAccountId, null);

        expect(account.ed25519AccountId, equals(testAccountId));
        expect(account.id, isNull);
      });

      test('creates MuxedAccount from G account ID with ID', () {
        final id = BigInt.from(12345);
        final account = MuxedAccount(testAccountId, id);

        expect(account.ed25519AccountId, equals(testAccountId));
        expect(account.id, equals(id));
      });

      test('creates MuxedAccount with BigInt ID zero', () {
        final id = BigInt.zero;
        final account = MuxedAccount(testAccountId, id);

        expect(account.ed25519AccountId, equals(testAccountId));
        expect(account.id, equals(BigInt.zero));
      });

      test('creates MuxedAccount with large BigInt ID', () {
        final id = BigInt.parse('18446744073709551615');
        final account = MuxedAccount(testAccountId, id);

        expect(account.ed25519AccountId, equals(testAccountId));
        expect(account.id, equals(id));
      });
    });

    group('MuxedAccount.fromAccountId', () {
      test('creates MuxedAccount from G account ID', () {
        final account = MuxedAccount.fromAccountId(testAccountId);

        expect(account, isNotNull);
        expect(account!.ed25519AccountId, equals(testAccountId));
        expect(account.id, isNull);
      });

      test('creates MuxedAccount from M muxed account ID', () {
        final account = MuxedAccount.fromAccountId(testMuxedAccountId);

        expect(account, isNotNull);
        expect(account!.id, isNotNull);
      });

      test('returns null for invalid account ID format', () {
        final account = MuxedAccount.fromAccountId('INVALID123');

        expect(account, isNull);
      });

      test('returns null for account ID with wrong prefix', () {
        final account = MuxedAccount.fromAccountId('X' + testAccountId.substring(1));

        expect(account, isNull);
      });
    });

    group('MuxedAccount.fromMed25519AccountId', () {
      test('creates MuxedAccount from M muxed account ID', () {
        final account = MuxedAccount.fromMed25519AccountId(testMuxedAccountId);

        expect(account.id, isNotNull);
        expect(account.ed25519AccountId, isNotEmpty);
      });

      test('decoded muxed account has correct underlying G account', () {
        final account = MuxedAccount.fromMed25519AccountId(testMuxedAccountId);

        expect(account.ed25519AccountId, equals(testAccountId));
      });

      test('decoded muxed account has correct ID', () {
        final account = MuxedAccount.fromMed25519AccountId(testMuxedAccountId);

        expect(account.id, equals(testMuxedId));
      });
    });

    group('MuxedAccount XDR serialization', () {
      test('XDR round-trip for standard ed25519 account', () {
        final account = MuxedAccount(testAccountId, null);
        final xdr = account.toXdr();
        final restored = MuxedAccount.fromXdr(xdr);

        expect(restored.ed25519AccountId, equals(testAccountId));
        expect(restored.id, isNull);
      });

      test('XDR round-trip for muxed account with ID', () {
        final id = BigInt.from(12345);
        final account = MuxedAccount(testAccountId, id);
        final xdr = account.toXdr();
        final restored = MuxedAccount.fromXdr(xdr);

        expect(restored.ed25519AccountId, equals(testAccountId));
        expect(restored.id, equals(id));
      });

      test('XDR discriminant is KEY_TYPE_ED25519 for standard account', () {
        final account = MuxedAccount(testAccountId, null);
        final xdr = account.toXdr();

        expect(xdr.discriminant, equals(XdrCryptoKeyType.KEY_TYPE_ED25519));
      });

      test('XDR discriminant is KEY_TYPE_MUXED_ED25519 for muxed account', () {
        final id = BigInt.from(12345);
        final account = MuxedAccount(testAccountId, id);
        final xdr = account.toXdr();

        expect(xdr.discriminant, equals(XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519));
      });
    });

    group('MuxedAccount.accountId getter', () {
      test('returns G address for standard account', () {
        final account = MuxedAccount(testAccountId, null);

        expect(account.accountId, equals(testAccountId));
        expect(account.accountId.startsWith('G'), isTrue);
      });

      test('returns M address for muxed account with ID', () {
        final id = BigInt.from(123);
        final account = MuxedAccount(testAccountId, id);

        expect(account.accountId.startsWith('M'), isTrue);
        expect(account.accountId.length, greaterThan(56));
      });

      test('accountId is consistent across multiple calls', () {
        final id = BigInt.from(12345);
        final account = MuxedAccount(testAccountId, id);

        final firstCall = account.accountId;
        final secondCall = account.accountId;

        expect(firstCall, equals(secondCall));
      });
    });

    group('MuxedAccount.ed25519AccountId getter', () {
      test('returns underlying G account for standard account', () {
        final account = MuxedAccount(testAccountId, null);

        expect(account.ed25519AccountId, equals(testAccountId));
      });

      test('returns underlying G account for muxed account', () {
        final id = BigInt.from(12345);
        final account = MuxedAccount(testAccountId, id);

        expect(account.ed25519AccountId, equals(testAccountId));
      });
    });

    group('MuxedAccount.id getter', () {
      test('returns null for standard account', () {
        final account = MuxedAccount(testAccountId, null);

        expect(account.id, isNull);
      });

      test('returns correct ID for muxed account', () {
        final id = BigInt.from(12345);
        final account = MuxedAccount(testAccountId, id);

        expect(account.id, equals(id));
      });

      test('returns zero ID for muxed account with zero', () {
        final id = BigInt.zero;
        final account = MuxedAccount(testAccountId, id);

        expect(account.id, equals(BigInt.zero));
      });
    });

    group('MuxedAccount med25519 operations', () {
      test('muxed account M address can be decoded back', () {
        final originalId = BigInt.from(999);
        final account = MuxedAccount(testAccountId, originalId);
        final mAddress = account.accountId;

        final decoded = MuxedAccount.fromMed25519AccountId(mAddress);

        expect(decoded.id, equals(originalId));
        expect(decoded.ed25519AccountId, equals(testAccountId));
      });

      test('muxed account round-trip preserves data', () {
        final originalId = BigInt.from(54321);
        final original = MuxedAccount(testAccountId, originalId);
        final mAddress = original.accountId;
        final restored = MuxedAccount.fromAccountId(mAddress);

        expect(restored, isNotNull);
        expect(restored!.id, equals(originalId));
        expect(restored.ed25519AccountId, equals(testAccountId));
      });
    });
  });
}
