import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const String _validRpcUrl = 'https://soroban-testnet.stellar.org';
const String _validPassphrase = 'Test SDF Network ; September 2015';
const String _publicPassphrase = 'Public Global Stellar Network ; September 2015';
const String _validWasmHash =
    'a000000000000000000000000000000000000000000000000000000000000000';
const String _validVerifier =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';

OZSmartAccountConfig _validConfig({
  String rpcUrl = _validRpcUrl,
  String networkPassphrase = _validPassphrase,
  String accountWasmHash = _validWasmHash,
  String webauthnVerifierAddress = _validVerifier,
}) {
  return OZSmartAccountConfig(
    rpcUrl: rpcUrl,
    networkPassphrase: networkPassphrase,
    accountWasmHash: accountWasmHash,
    webauthnVerifierAddress: webauthnVerifierAddress,
  );
}

void main() {
  group('OZSmartAccountConfig - ConfigValidationTest', () {
    test('testConfigDefaults_optionalFieldsHaveCorrectDefaults', () {
      final config = _validConfig();

      expect(config.deployerKeypair, isNull);
      expect(config.rpId, isNull);
      expect(config.rpName, 'Smart Account');
      expect(config.sessionExpiryMs, OZConstants.defaultSessionExpiryMs);
      expect(config.signatureExpirationLedgers, Util.ledgersPerHour);
      expect(config.timeoutInSeconds, OZConstants.defaultTimeoutSeconds);
      expect(config.relayerUrl, isNull);
      expect(config.indexerUrl, isNull);
      expect(config.webauthnProvider, isNull);
    });

    test('testConfigDefaults_requiredFieldsStored', () {
      final config = _validConfig();

      expect(config.rpcUrl, _validRpcUrl);
      expect(config.networkPassphrase, _validPassphrase);
      expect(config.accountWasmHash, _validWasmHash);
      expect(config.webauthnVerifierAddress, _validVerifier);
    });

    test('testWebauthnVerifierAddress_whitespaceOnlyThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: '    ',
        ),
        throwsA(isA<InvalidConfig>()),
      );
    });

    test('testWebauthnVerifierAddress_startsWithGThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: 'G${'A' * 55}',
        ),
        throwsA(isA<InvalidConfig>()),
      );
    });

    test('testWebauthnVerifierAddress_tooShortThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: 'CABC',
        ),
        throwsA(isA<InvalidConfig>()),
      );
    });

    test('testWebauthnVerifierAddress_tooLongThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: 'C${'A' * 56}',
        ),
        throwsA(isA<InvalidConfig>()),
      );
    });

    test('testRpcUrl_whitespaceOnlyThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: '   ',
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: _validVerifier,
        ),
        throwsA(isA<MissingConfig>()),
      );
    });

    test('testNetworkPassphrase_whitespaceOnlyThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: '   ',
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: _validVerifier,
        ),
        throwsA(isA<MissingConfig>()),
      );
    });

    test('testAccountWasmHash_whitespaceOnlyThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: '   ',
          webauthnVerifierAddress: _validVerifier,
        ),
        throwsA(isA<MissingConfig>()),
      );
    });

    test('testAccountWasmHash_invalidHexThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: 'not_a_valid_hex_hash',
          webauthnVerifierAddress: _validVerifier,
        ),
        throwsA(isA<InvalidConfig>()),
      );
    });

    test('testAccountWasmHash_tooShortHexThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: 'abcdef',
          webauthnVerifierAddress: _validVerifier,
        ),
        throwsA(isA<InvalidConfig>()),
      );
    });

    test('testBuilder_allOptionalFields', () {
      final config = OZSmartAccountConfig.builder(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      )
          .rpName('My Custom Wallet')
          .rpId('example.com')
          .sessionExpiryMs(86400000)
          .signatureExpirationLedgers(1440)
          .timeoutInSeconds(60)
          .relayerUrl('https://relayer.example.com')
          .indexerUrl('https://indexer.example.com')
          .build();

      expect(config.rpName, 'My Custom Wallet');
      expect(config.rpId, 'example.com');
      expect(config.sessionExpiryMs, 86400000);
      expect(config.signatureExpirationLedgers, 1440);
      expect(config.timeoutInSeconds, 60);
      expect(config.relayerUrl, 'https://relayer.example.com');
      expect(config.indexerUrl, 'https://indexer.example.com');
    });

    test('testBuilder_defaultValues', () {
      final config = OZSmartAccountConfig.builder(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      ).build();

      expect(config.rpName, 'Smart Account');
      expect(config.rpId, isNull);
      expect(config.sessionExpiryMs, OZConstants.defaultSessionExpiryMs);
      expect(config.signatureExpirationLedgers, Util.ledgersPerHour);
      expect(config.timeoutInSeconds, OZConstants.defaultTimeoutSeconds);
      expect(config.relayerUrl, isNull);
      expect(config.indexerUrl, isNull);
      expect(config.deployerKeypair, isNull);
    });

    test('testBuilder_producesIdenticalConfigToConstructor', () {
      final constructorConfig = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
        rpName: 'Test',
        sessionExpiryMs: 100000,
        relayerUrl: 'https://relayer.test',
      );

      final builderConfig = OZSmartAccountConfig.builder(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      )
          .rpName('Test')
          .sessionExpiryMs(100000)
          .relayerUrl('https://relayer.test')
          .build();

      expect(builderConfig, equals(constructorConfig));
    });

    test('testBuilder_nullOptionalValues', () {
      final config = OZSmartAccountConfig.builder(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      )
          .rpId(null)
          .relayerUrl(null)
          .indexerUrl(null)
          .deployerKeypair(null)
          .build();

      expect(config.rpId, isNull);
      expect(config.relayerUrl, isNull);
      expect(config.indexerUrl, isNull);
      expect(config.deployerKeypair, isNull);
    });

    test('testBuilder_chainable', () {
      final builder = OZSmartAccountConfig.builder(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      );

      final result = builder
          .rpName('A')
          .rpId('b.com')
          .sessionExpiryMs(1000)
          .signatureExpirationLedgers(100)
          .timeoutInSeconds(10)
          .relayerUrl('https://r.com')
          .indexerUrl('https://i.com')
          .deployerKeypair(null);

      expect(identical(result, builder), isTrue);

      final config = result.build();
      expect(config.rpName, 'A');
      expect(config.rpId, 'b.com');
    });

    test('testConfigEquality_identicalConfigsAreEqual', () {
      final config1 = _validConfig();
      final config2 = _validConfig();

      expect(config1, equals(config2));
      expect(config1.hashCode, config2.hashCode);
    });

    test('testConfigEquality_differentRpcUrlNotEqual', () {
      final config1 = OZSmartAccountConfig(
        rpcUrl: 'https://rpc1.example.com',
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      );
      final config2 = OZSmartAccountConfig(
        rpcUrl: 'https://rpc2.example.com',
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      );

      expect(config1 == config2, isFalse);
    });

    test('testConfigCopy_withModifiedFields', () {
      final original = _validConfig();
      final modified = original.copyWith(rpName: 'Modified Wallet');

      expect(modified.rpName, 'Modified Wallet');
      expect(modified.rpcUrl, original.rpcUrl);
      expect(modified.networkPassphrase, original.networkPassphrase);
    });

    test('testEffectiveIndexerUrl_explicitUrlTakesPrecedence', () {
      final config = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
        indexerUrl: 'https://custom-indexer.example.com',
      );

      expect(
        config.effectiveIndexerUrl(),
        'https://custom-indexer.example.com',
      );
    });

    test('testEffectiveIndexerUrl_noExplicitUrlFallsBackToDefault', () {
      final config = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      );

      // For testnet a built-in default is configured; for mainnet a default
      // also exists. The test requires only that the call resolves without
      // throwing.
      final url = config.effectiveIndexerUrl();
      expect(url, isNotNull);
    });

    test('testEffectiveIndexerUrl_unknownNetworkReturnsNull', () {
      final config = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: 'Unknown Network ; January 2099',
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      );
      expect(config.effectiveIndexerUrl(), isNull,
          reason:
              'No explicit indexerUrl + no default for the passphrase must '
              'resolve to null');
    });

    test('testGetDeployer_defaultDeployerIsDeterministic', () async {
      final config = _validConfig();

      final deployer1 = await config.effectiveDeployer();
      final deployer2 = await config.effectiveDeployer();

      expect(deployer1, isNotNull);
      expect(deployer2, isNotNull);
      expect(deployer1.accountId, deployer2.accountId);
    });

    test('testGetDeployer_customDeployerTakesPrecedence', () async {
      final customDeployer = KeyPair.random();
      final config = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
        deployerKeypair: customDeployer,
      );

      final deployer = await config.effectiveDeployer();
      expect(deployer.accountId, customDeployer.accountId);
    });

    test('testConfig_testnetPassphrase', () {
      final config = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      );
      expect(config.networkPassphrase, _validPassphrase);
    });

    test('testConfig_mainnetPassphrase', () {
      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-mainnet.stellar.org',
        networkPassphrase: _publicPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      );
      expect(config.networkPassphrase, _publicPassphrase);
    });

    test('testConfig_customPassphrase', () {
      const customPassphrase = 'My Custom Stellar Network ; January 2026';
      final config = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: customPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      );
      expect(config.networkPassphrase, customPassphrase);
    });

    test('testOZConstants_defaultSessionExpiryMs', () {
      expect(
        OZConstants.defaultSessionExpiryMs,
        7 * 24 * 60 * 60 * 1000,
      );
    });

    test('testUtil_ledgersPerHour', () {
      expect(Util.ledgersPerHour, 720);
    });

    test('testOZConstants_defaultTimeoutSeconds', () {
      expect(OZConstants.defaultTimeoutSeconds, 30);
    });
  });
}
