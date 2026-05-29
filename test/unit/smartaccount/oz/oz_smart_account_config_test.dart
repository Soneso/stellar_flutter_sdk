import 'dart:typed_data';

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

    test('testConfigCopy_withoutRpName_preservesOriginalRpName', () {
      // copyWith without rpName must fall through to `rpName ?? this.rpName`
      // (line 341 of oz_smart_account_config.dart).
      final original = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
        rpName: 'Original Name',
      );
      final copied = original.copyWith(rpcUrl: 'https://rpc2.example.com');
      expect(copied.rpName, 'Original Name',
          reason: 'rpName must be preserved when not provided to copyWith');
      expect(copied.rpcUrl, 'https://rpc2.example.com');
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

    test('testSignatureExpirationLedgers_zeroThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: _validVerifier,
          signatureExpirationLedgers: 0,
        ),
        throwsA(isA<InvalidConfig>().having(
          (e) => e.toString(),
          'message',
          contains('signatureExpirationLedgers must be in [1, 535680]'),
        )),
      );
    });

    test('testSignatureExpirationLedgers_negativeThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: _validVerifier,
          signatureExpirationLedgers: -1,
        ),
        throwsA(isA<InvalidConfig>().having(
          (e) => e.toString(),
          'message',
          contains('signatureExpirationLedgers must be in [1, 535680]'),
        )),
      );
    });

    test('testSignatureExpirationLedgers_aboveProtocolCapThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: _validVerifier,
          signatureExpirationLedgers: 535681,
        ),
        throwsA(isA<InvalidConfig>().having(
          (e) => e.toString(),
          'message',
          contains('signatureExpirationLedgers must be in [1, 535680]'),
        )),
      );
    });

    test('testSignatureExpirationLedgers_atProtocolCapAccepted', () {
      final config = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
        signatureExpirationLedgers: 535680,
      );
      expect(config.signatureExpirationLedgers, equals(535680));
    });

    test('testTimeoutInSeconds_zeroThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: _validVerifier,
          timeoutInSeconds: 0,
        ),
        throwsA(isA<InvalidConfig>().having(
          (e) => e.toString(),
          'message',
          contains('timeoutInSeconds must be in [1, 600]'),
        )),
      );
    });

    test('testTimeoutInSeconds_negativeThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: _validVerifier,
          timeoutInSeconds: -5,
        ),
        throwsA(isA<InvalidConfig>().having(
          (e) => e.toString(),
          'message',
          contains('timeoutInSeconds must be in [1, 600]'),
        )),
      );
    });

    test('testTimeoutInSeconds_aboveCapThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: _validVerifier,
          timeoutInSeconds: 601,
        ),
        throwsA(isA<InvalidConfig>().having(
          (e) => e.toString(),
          'message',
          contains('timeoutInSeconds must be in [1, 600]'),
        )),
      );
    });

    test('testTimeoutInSeconds_atCapAccepted', () {
      final config = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
        timeoutInSeconds: 600,
      );
      expect(config.timeoutInSeconds, equals(600));
    });

    test('testMaxContextRuleScanId_negativeThrows', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: _validVerifier,
          maxContextRuleScanId: -1,
        ),
        throwsA(isA<InvalidConfig>().having(
          (e) => e.toString(),
          'message',
          contains('maxContextRuleScanId must be non-negative'),
        )),
      );
    });

    test('testMaxContextRuleScanId_zeroAccepted', () {
      final config = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
        maxContextRuleScanId: 0,
      );
      expect(config.maxContextRuleScanId, 0);
    });

    test('testBuilder_webauthnProvider_setter', () {
      final config = OZSmartAccountConfig.builder(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      )
          .webauthnProvider(null)
          .build();

      expect(config.webauthnProvider, isNull);
    });

    test('testBuilder_storage_setter', () {
      final storage = InMemoryStorageAdapter();
      final config = OZSmartAccountConfig.builder(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      )
          .storage(storage)
          .build();

      expect(config.storage, same(storage));
    });

    test('testBuilder_externalWallet_setter', () {
      final config = OZSmartAccountConfig.builder(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      )
          .externalWallet(null)
          .build();

      expect(config.externalWallet, isNull);
    });

    test('testBuilder_externalEd25519Adapter_setter', () {
      final config = OZSmartAccountConfig.builder(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      )
          .externalEd25519Adapter(null)
          .build();

      expect(config.externalEd25519Adapter, isNull);
    });

    test('testBuilder_maxContextRuleScanId_setter', () {
      final config = OZSmartAccountConfig.builder(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      )
          .maxContextRuleScanId(25)
          .build();

      expect(config.maxContextRuleScanId, 25);
    });

    test('testCreateDefaultDeployer_succeeds', () async {
      final deployer = await OZSmartAccountConfig.createDefaultDeployer();
      expect(deployer, isNotNull);
      expect(deployer.accountId.startsWith('G'), isTrue);
    });

    // -------------------------------------------------------------------------
    // copyWith — externalEd25519Adapter both branches
    //
    // The sentinel flag pattern mirrors the existing setExternalWallet pattern.
    // Both branches of the ternary in copyWith must be exercised:
    //   (a) without the flag → the adapter is preserved from the original.
    //   (b) with the flag + null → the adapter is cleared to null.
    // -------------------------------------------------------------------------

    test(
        'testCopyWith_externalEd25519Adapter_withoutFlag_preservesOriginalAdapter',
        () {
      final adapter = _StubEd25519Adapter();
      final original = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
        externalEd25519Adapter: adapter,
      );

      // copyWith without setExternalEd25519Adapter: true must preserve the
      // adapter from the original config even when the param is omitted.
      final copied = original.copyWith(rpName: 'Other Name');

      expect(
        identical(copied.externalEd25519Adapter, adapter),
        isTrue,
        reason:
            'externalEd25519Adapter must be preserved when setExternalEd25519Adapter is false',
      );
    });

    test(
        'testCopyWith_externalEd25519Adapter_withFlagAndNull_clearsAdapter',
        () {
      final adapter = _StubEd25519Adapter();
      final original = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
        externalEd25519Adapter: adapter,
      );

      // Setting the sentinel flag to true with a null adapter must clear the
      // field to null in the produced config.
      final cleared = original.copyWith(
        setExternalEd25519Adapter: true,
        externalEd25519Adapter: null,
      );

      expect(
        cleared.externalEd25519Adapter,
        isNull,
        reason:
            'externalEd25519Adapter must be null when setExternalEd25519Adapter is true and adapter is null',
      );
    });

    test(
        'testCopyWith_externalEd25519Adapter_withFlagAndNonNull_replacesAdapter',
        () {
      final original = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
      );
      final adapter = _StubEd25519Adapter();

      final updated = original.copyWith(
        setExternalEd25519Adapter: true,
        externalEd25519Adapter: adapter,
      );

      expect(
        identical(updated.externalEd25519Adapter, adapter),
        isTrue,
        reason: 'copyWith with flag true must install the supplied adapter',
      );
    });

    test(
        'testEquality_differentExternalEd25519Adapter_notEqual',
        () {
      final a = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
        externalEd25519Adapter: _StubEd25519Adapter(),
      );
      final b = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
        externalEd25519Adapter: _StubEd25519Adapter(),
      );

      // Two distinct adapter instances must break equality (identical() check).
      expect(a == b, isFalse);
    });

    test(
        'testEquality_sameExternalEd25519AdapterInstance_equal',
        () {
      final adapter = _StubEd25519Adapter();
      final a = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
        externalEd25519Adapter: adapter,
      );
      final b = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: _validPassphrase,
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
        externalEd25519Adapter: adapter,
      );

      // Same instance must produce equal configs.
      expect(a == b, isTrue);
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}

/// Minimal [OZExternalEd25519SignerAdapter] stub used to test equality and
/// copyWith behaviour. Never asked to sign in config-level tests.
class _StubEd25519Adapter extends OZExternalEd25519SignerAdapter {
  @override
  bool canSignFor(String verifierAddress, Uint8List publicKey) => false;

  @override
  Future<Uint8List> signAuthDigest(
    Uint8List authDigest,
    Uint8List publicKey,
  ) async =>
      throw UnsupportedError('_StubEd25519Adapter.signAuthDigest not used in config tests');
}
