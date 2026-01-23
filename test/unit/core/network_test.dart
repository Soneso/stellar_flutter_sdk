import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';

void main() {
  group('Network', () {
    group('Network constants', () {
      test('Network.PUBLIC has correct passphrase', () {
        final network = Network.PUBLIC;

        expect(
          network.networkPassphrase,
          equals('Public Global Stellar Network ; September 2015'),
        );
      });

      test('Network.TESTNET has correct passphrase', () {
        final network = Network.TESTNET;

        expect(
          network.networkPassphrase,
          equals('Test SDF Network ; September 2015'),
        );
      });

      test('Network.FUTURENET has correct passphrase', () {
        final network = Network.FUTURENET;

        expect(
          network.networkPassphrase,
          equals('Test SDF Future Network ; October 2022'),
        );
      });
    });

    group('Custom network creation', () {
      test('creates custom network with passphrase', () {
        final customPassphrase = 'Custom Network ; January 2024';
        final network = Network(customPassphrase);

        expect(network.networkPassphrase, equals(customPassphrase));
      });

      test('creates custom network with empty passphrase', () {
        final network = Network('');

        expect(network.networkPassphrase, equals(''));
      });

      test('creates custom network with special characters', () {
        final customPassphrase = 'Test Network 123 !@# ; December 2025';
        final network = Network(customPassphrase);

        expect(network.networkPassphrase, equals(customPassphrase));
      });
    });

    group('Network ID computation', () {
      test('Network.PUBLIC has non-null network ID', () {
        final network = Network.PUBLIC;
        final networkId = network.networkId;

        expect(networkId, isNotNull);
        expect(networkId, isA<Uint8List>());
      });

      test('Network.TESTNET has non-null network ID', () {
        final network = Network.TESTNET;
        final networkId = network.networkId;

        expect(networkId, isNotNull);
        expect(networkId, isA<Uint8List>());
      });

      test('Network.FUTURENET has non-null network ID', () {
        final network = Network.FUTURENET;
        final networkId = network.networkId;

        expect(networkId, isNotNull);
        expect(networkId, isA<Uint8List>());
      });

      test('Network ID is 32 bytes for PUBLIC network', () {
        final network = Network.PUBLIC;
        final networkId = network.networkId;

        expect(networkId!.length, equals(32));
      });

      test('Network ID is 32 bytes for TESTNET network', () {
        final network = Network.TESTNET;
        final networkId = network.networkId;

        expect(networkId!.length, equals(32));
      });

      test('Different networks have different network IDs', () {
        final publicId = Network.PUBLIC.networkId;
        final testnetId = Network.TESTNET;
        final futurenetId = Network.FUTURENET.networkId;

        expect(publicId, isNot(equals(testnetId)));
        expect(publicId, isNot(equals(futurenetId)));
        expect(testnetId, isNot(equals(futurenetId)));
      });

      test('Same passphrase produces same network ID', () {
        final network1 = Network('Custom Network');
        final network2 = Network('Custom Network');

        final id1 = network1.networkId;
        final id2 = network2.networkId;

        expect(id1, equals(id2));
      });

      test('Custom network has correct length network ID', () {
        final network = Network('Custom Network ; Test');
        final networkId = network.networkId;

        expect(networkId, isNotNull);
        expect(networkId!.length, equals(32));
      });
    });

    group('Network passphrase getter', () {
      test('networkPassphrase getter returns correct value', () {
        final customPassphrase = 'Test Passphrase';
        final network = Network(customPassphrase);

        expect(network.networkPassphrase, equals(customPassphrase));
      });

      test('networkPassphrase is immutable after creation', () {
        final network = Network('Original');
        final passphrase1 = network.networkPassphrase;
        final passphrase2 = network.networkPassphrase;

        expect(passphrase1, equals(passphrase2));
        expect(passphrase1, equals('Original'));
      });
    });
  });
}
