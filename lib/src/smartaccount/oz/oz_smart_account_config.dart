// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import '../../key_pair.dart';
import '../../util.dart';
import '../core/smart_account_errors.dart';
import '../core/web_authn_provider.dart';
import 'oz_constants.dart';
import 'oz_external_signer_manager.dart';
import 'oz_indexer_client.dart';
import 'oz_storage_adapter.dart';

/// Configuration for OpenZeppelin Smart Account operations.
///
/// Defines all parameters required to interact with OpenZeppelin smart
/// accounts on Stellar/Soroban: network connectivity settings, contract
/// addresses, and operational parameters.
///
/// Example:
///
/// ```dart
/// final config = OZSmartAccountConfig(
///   rpcUrl: 'https://soroban-testnet.stellar.org',
///   networkPassphrase: 'Test SDF Network ; September 2015',
///   accountWasmHash: 'abc123...',
///   webauthnVerifierAddress: 'CBCD1234...',
/// );
///
/// // With custom settings using the builder
/// final customConfig = OZSmartAccountConfig.builder(
///   rpcUrl: 'https://soroban-testnet.stellar.org',
///   networkPassphrase: 'Test SDF Network ; September 2015',
///   accountWasmHash: 'abc123...',
///   webauthnVerifierAddress: 'CBCD1234...',
/// )
///     .rpName('My Custom Wallet')
///     .sessionExpiryMs(86400000)
///     .relayerUrl('https://relayer.example.com')
///     .storage(myPersistentStorage)
///     .externalWallet(freighterAdapter)
///     .build();
/// ```
///
/// | Field                       | Required | Default                |
/// |-----------------------------|----------|------------------------|
/// | rpcUrl                      | Yes      | -                      |
/// | networkPassphrase           | Yes      | -                      |
/// | accountWasmHash             | Yes      | -                      |
/// | webauthnVerifierAddress     | Yes      | -                      |
/// | deployerKeypair             | No       | Deterministic deployer |
/// | rpId                        | No       | Browser default        |
/// | rpName                      | No       | "Smart Account"        |
/// | sessionExpiryMs             | No       | 604800000 (7 days)     |
/// | signatureExpirationLedgers  | No       | 720 (~1 hour)          |
/// | timeoutInSeconds            | No       | 30                     |
/// | relayerUrl                  | No       | null                   |
/// | indexerUrl                  | No       | null                   |
/// | webauthnProvider            | No       | null                   |
/// | storage                     | No       | InMemoryStorageAdapter |
/// | externalWallet              | No       | null                   |
/// | externalSignerManager       | No       | null                   |
/// | maxContextRuleScanId        | No       | 50                     |
///
/// Throws [ConfigurationException] if required parameters are blank or
/// invalid (e.g. `accountWasmHash` is not a 64-character hex string, or
/// `webauthnVerifierAddress` is not a valid C-address).
class OZSmartAccountConfig {
  /// Constructs a configuration for OpenZeppelin Smart Account operations.
  ///
  /// The required parameters [rpcUrl], [networkPassphrase], [accountWasmHash],
  /// and [webauthnVerifierAddress] are validated in the constructor; all
  /// optional parameters fall back to their documented defaults.
  ///
  /// When [storage] is omitted a fresh [InMemoryStorageAdapter] is allocated.
  /// All [InMemoryStorageAdapter] instances compare equal so two configs
  /// constructed with identical inputs (including the default storage) are
  /// equal as well.
  OZSmartAccountConfig({
    required this.rpcUrl,
    required this.networkPassphrase,
    required this.accountWasmHash,
    required this.webauthnVerifierAddress,
    this.deployerKeypair,
    this.rpId,
    this.rpName = 'Smart Account',
    this.sessionExpiryMs = OZConstants.defaultSessionExpiryMs,
    this.signatureExpirationLedgers = Util.ledgersPerHour,
    this.timeoutInSeconds = OZConstants.defaultTimeoutSeconds,
    this.relayerUrl,
    this.indexerUrl,
    this.webauthnProvider,
    StorageAdapter? storage,
    this.externalWallet,
    this.externalSignerManager,
    this.maxContextRuleScanId = 50,
  }) : storage = storage ?? InMemoryStorageAdapter() {
    if (rpcUrl.trim().isEmpty) {
      throw ConfigurationException.missingConfig('rpcUrl');
    }
    if (networkPassphrase.trim().isEmpty) {
      throw ConfigurationException.missingConfig('networkPassphrase');
    }
    if (accountWasmHash.trim().isEmpty) {
      throw ConfigurationException.missingConfig('accountWasmHash');
    }
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(accountWasmHash)) {
      throw ConfigurationException.invalidConfig(
        'accountWasmHash must be a 64-character hex string '
        '(SHA-256 of WASM), got: $accountWasmHash',
      );
    }
    if (!StrKey.isValidContractId(webauthnVerifierAddress)) {
      throw ConfigurationException.invalidConfig(
        'webauthnVerifierAddress must be a valid contract address '
        '(C...), got: $webauthnVerifierAddress',
      );
    }
    if (maxContextRuleScanId < 0) {
      throw ConfigurationException.invalidConfig(
        'maxContextRuleScanId must be non-negative, '
        'got: $maxContextRuleScanId',
      );
    }
    // why: cap `signatureExpirationLedgers` at 535_680 (the protocol-level
    // ~one-month limit at 5 seconds per ledger) and reject zero / negative
    // values so the signing pass cannot produce an immediately-expired or
    // beyond-protocol-limit expiration ledger.
    if (signatureExpirationLedgers < 1 || signatureExpirationLedgers > 535680) {
      throw ConfigurationException.invalidConfig(
        'signatureExpirationLedgers must be in [1, 535680] (one ledger to '
        '~one month at 5s ledgers), got: $signatureExpirationLedgers',
      );
    }
    // why: cap `timeoutInSeconds` at 600 seconds so a misconfigured kit
    // cannot freeze a UI ceremony beyond 10 minutes and reject zero so
    // every Stellar transaction has a non-degenerate validity window.
    if (timeoutInSeconds < 1 || timeoutInSeconds > 600) {
      throw ConfigurationException.invalidConfig(
        'timeoutInSeconds must be in [1, 600], got: $timeoutInSeconds',
      );
    }
  }

  /// Soroban RPC endpoint URL. Example:
  /// `https://soroban-testnet.stellar.org`.
  final String rpcUrl;

  /// Stellar network passphrase.
  ///
  /// Examples:
  /// - Testnet: `Test SDF Network ; September 2015`
  /// - Mainnet: `Public Global Stellar Network ; September 2015`
  final String networkPassphrase;

  /// WASM hash of the smart account contract (64-character hex string).
  ///
  /// SHA-256 hash of the smart account contract WASM code, used for
  /// deploying new smart account instances.
  final String accountWasmHash;

  /// Contract address of the WebAuthn signature verifier (C-address).
  ///
  /// Verifier contract validates secp256r1 signatures from
  /// WebAuthn/passkeys.
  final String webauthnVerifierAddress;

  /// Keypair used for deploying smart account contracts.
  ///
  /// When `null` a deterministic deployer is derived from
  /// `SHA256("openzeppelin-smart-account-kit")`. Production apps typically
  /// use a custom deployer for attribution and traceability. The deployer
  /// only pays for deployment transactions; it does not control user
  /// wallets.
  final KeyPair? deployerKeypair;

  /// WebAuthn Relying Party ID.
  ///
  /// Should match the domain where WebAuthn credentials are created. When
  /// `null` the browser uses the current domain. Example: `example.com`.
  final String? rpId;

  /// WebAuthn Relying Party name displayed to users during authentication.
  /// Default: `Smart Account`.
  final String rpName;

  /// Session expiry time in milliseconds. Sessions enable silent
  /// reconnection without re-authentication. Default: 604_800_000
  /// (7 days).
  final int sessionExpiryMs;

  /// Signature expiration in ledgers for auth entries. Auth entries expire
  /// after this many ledgers to prevent replay attacks. Default: 720
  /// (about one hour at five seconds per ledger).
  final int signatureExpirationLedgers;

  /// Default timeout for operations in seconds. Used for network requests
  /// and transaction submission. Default: 30.
  final int timeoutInSeconds;

  /// Optional relayer endpoint URL for fee sponsoring.
  ///
  /// When set, enables gasless transactions by submitting through a
  /// fee-bump relayer. Allows users with empty wallets to transact.
  final String? relayerUrl;

  /// Optional indexer endpoint URL for credential-to-contract mapping.
  ///
  /// The indexer maps WebAuthn credential IDs to deployed smart account
  /// contract addresses, enabling "Connect Wallet" functionality.
  final String? indexerUrl;

  /// Optional WebAuthn provider for passkey authentication.
  ///
  /// Platform-specific implementation that handles WebAuthn registration
  /// and authentication. Required for signing transactions with passkeys.
  final WebAuthnProvider? webauthnProvider;

  /// Storage adapter for persisting credentials and session data. Defaults
  /// to [InMemoryStorageAdapter] (non-persistent, suitable for testing).
  final StorageAdapter storage;

  /// External wallet adapter for signing transactions with an external
  /// signer. When set, the kit delegates transaction signing to this
  /// adapter instead of using WebAuthn credentials.
  final ExternalWalletAdapter? externalWallet;

  /// Optional external-signer manager for Ed25519 multi-signer signing
  /// ceremonies.
  ///
  /// Consumers construct [OZExternalSignerManager] separately, register
  /// Ed25519 signing keypairs via
  /// [OZExternalSignerManager.addEd25519FromRawKey], and supply the manager
  /// here so that `kit.externalSignerManager` can forward signing requests
  /// to it during multi-signer operations that include
  /// `SelectedSignerEd25519` entries.
  ///
  /// When `null`, Ed25519 signers in `selectedSigners` cause
  /// [OZMultiSignerManager] to throw [InvalidInput].
  final OZExternalSignerManager? externalSignerManager;

  /// Maximum rule ID to scan when iterating context rules.
  ///
  /// The contract assigns monotonically increasing IDs to context rules.
  /// When rules are removed, their IDs leave gaps. Iteration walks IDs from
  /// 0 up to this value to find all active rules. Increase if the account
  /// has had many add/remove cycles. Default: 50.
  final int maxContextRuleScanId;

  /// Creates a deterministic deployer keypair for smart account deployment.
  ///
  /// Derives an Ed25519 keypair from
  /// `SHA-256("openzeppelin-smart-account-kit")`. The seed string is fixed
  /// across every Smart Account Kit implementation so the resulting
  /// account ID is reproducible and recognisable on-chain. The deployer
  /// only pays deployment fees and does not control user wallets.
  /// Suitable for testing and simple deployments; production apps typically
  /// use a custom deployer for attribution and traceability.
  ///
  /// Throws [ConfigurationException] if seed generation fails.
  static Future<KeyPair> createDefaultDeployer() async {
    try {
      // why: this exact byte string is shared with every Smart Account Kit
      // implementation. Changing it produces a different deployer keypair and
      // therefore different smart-account contract IDs for every existing
      // wallet derived against the previous default.
      const seedString = 'openzeppelin-smart-account-kit';
      final seedBytes = Uint8List.fromList(utf8.encode(seedString));
      final seedHash = Util.hash(seedBytes);
      return KeyPair.fromSecretSeedList(seedHash);
    } catch (e) {
      throw ConfigurationException.invalidConfig(
        'Failed to create default deployer keypair: $e',
        cause: e,
      );
    }
  }

  /// Creates a [Builder] for constructing an [OZSmartAccountConfig] with a
  /// fluent API.
  ///
  /// Example:
  ///
  /// ```dart
  /// final config = OZSmartAccountConfig.builder(
  ///   rpcUrl: 'https://soroban-testnet.stellar.org',
  ///   networkPassphrase: 'Test SDF Network ; September 2015',
  ///   accountWasmHash: 'abc123...',
  ///   webauthnVerifierAddress: 'CBCD1234...',
  /// )
  ///     .rpName('My Wallet')
  ///     .sessionExpiryMs(86400000)
  ///     .relayerUrl('https://relayer.example.com')
  ///     .storage(myPersistentStorage)
  ///     .externalWallet(freighterAdapter)
  ///     .build();
  /// ```
  static OZSmartAccountConfigBuilder builder({
    required String rpcUrl,
    required String networkPassphrase,
    required String accountWasmHash,
    required String webauthnVerifierAddress,
  }) =>
      OZSmartAccountConfigBuilder(
        rpcUrl: rpcUrl,
        networkPassphrase: networkPassphrase,
        accountWasmHash: accountWasmHash,
        webauthnVerifierAddress: webauthnVerifierAddress,
      );

  /// Returns the deployer keypair, creating the deterministic default if
  /// none is configured.
  ///
  /// Asynchronous because the default-deployer derivation hashes a fixed
  /// seed and constructs an Ed25519 keypair.
  ///
  /// Throws [ConfigurationException] if default deployer creation fails.
  Future<KeyPair> effectiveDeployer() async {
    final configured = deployerKeypair;
    if (configured != null) return configured;
    return createDefaultDeployer();
  }

  /// Returns the indexer URL after applying fallback logic.
  ///
  /// If [indexerUrl] is explicitly configured it is returned. Otherwise the
  /// well-known default URL for the network's passphrase is returned, or
  /// `null` when no default exists.
  String? effectiveIndexerUrl() {
    return indexerUrl ?? OZIndexerClient.getDefaultUrl(networkPassphrase);
  }

  /// Returns a copy of this configuration with the given fields replaced.
  ///
  /// Each named argument defaults to the current value of the corresponding
  /// field. Pass [setDeployerKeypair] / [setRpId] / [setRelayerUrl] /
  /// [setIndexerUrl] / [setWebauthnProvider] / [setExternalWallet] /
  /// [setExternalSignerManager] as `true` together with the corresponding
  /// `null` argument to clear an optional field.
  OZSmartAccountConfig copyWith({
    String? rpcUrl,
    String? networkPassphrase,
    String? accountWasmHash,
    String? webauthnVerifierAddress,
    KeyPair? deployerKeypair,
    bool setDeployerKeypair = false,
    String? rpId,
    bool setRpId = false,
    String? rpName,
    int? sessionExpiryMs,
    int? signatureExpirationLedgers,
    int? timeoutInSeconds,
    String? relayerUrl,
    bool setRelayerUrl = false,
    String? indexerUrl,
    bool setIndexerUrl = false,
    WebAuthnProvider? webauthnProvider,
    bool setWebauthnProvider = false,
    StorageAdapter? storage,
    ExternalWalletAdapter? externalWallet,
    bool setExternalWallet = false,
    OZExternalSignerManager? externalSignerManager,
    bool setExternalSignerManager = false,
    int? maxContextRuleScanId,
  }) {
    return OZSmartAccountConfig(
      rpcUrl: rpcUrl ?? this.rpcUrl,
      networkPassphrase: networkPassphrase ?? this.networkPassphrase,
      accountWasmHash: accountWasmHash ?? this.accountWasmHash,
      webauthnVerifierAddress:
          webauthnVerifierAddress ?? this.webauthnVerifierAddress,
      deployerKeypair: setDeployerKeypair ? deployerKeypair : (deployerKeypair ?? this.deployerKeypair),
      rpId: setRpId ? rpId : (rpId ?? this.rpId),
      rpName: rpName ?? this.rpName,
      sessionExpiryMs: sessionExpiryMs ?? this.sessionExpiryMs,
      signatureExpirationLedgers:
          signatureExpirationLedgers ?? this.signatureExpirationLedgers,
      timeoutInSeconds: timeoutInSeconds ?? this.timeoutInSeconds,
      relayerUrl: setRelayerUrl ? relayerUrl : (relayerUrl ?? this.relayerUrl),
      indexerUrl: setIndexerUrl ? indexerUrl : (indexerUrl ?? this.indexerUrl),
      webauthnProvider: setWebauthnProvider
          ? webauthnProvider
          : (webauthnProvider ?? this.webauthnProvider),
      storage: storage ?? this.storage,
      externalWallet: setExternalWallet
          ? externalWallet
          : (externalWallet ?? this.externalWallet),
      externalSignerManager: setExternalSignerManager
          ? externalSignerManager
          : (externalSignerManager ?? this.externalSignerManager),
      maxContextRuleScanId: maxContextRuleScanId ?? this.maxContextRuleScanId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZSmartAccountConfig) return false;
    return rpcUrl == other.rpcUrl &&
        networkPassphrase == other.networkPassphrase &&
        accountWasmHash == other.accountWasmHash &&
        webauthnVerifierAddress == other.webauthnVerifierAddress &&
        deployerKeypair == other.deployerKeypair &&
        rpId == other.rpId &&
        rpName == other.rpName &&
        sessionExpiryMs == other.sessionExpiryMs &&
        signatureExpirationLedgers == other.signatureExpirationLedgers &&
        timeoutInSeconds == other.timeoutInSeconds &&
        relayerUrl == other.relayerUrl &&
        indexerUrl == other.indexerUrl &&
        webauthnProvider == other.webauthnProvider &&
        storage == other.storage &&
        externalWallet == other.externalWallet &&
        // why: OZExternalSignerManager is a stateful object; value equality
        // is meaningless. Use identity (identical) so two configs that
        // reference the same manager instance compare equal, while different
        // instances — even with the same network passphrase — do not.
        identical(externalSignerManager, other.externalSignerManager) &&
        maxContextRuleScanId == other.maxContextRuleScanId;
  }

  @override
  int get hashCode => Object.hashAll([
        rpcUrl,
        networkPassphrase,
        accountWasmHash,
        webauthnVerifierAddress,
        deployerKeypair,
        rpId,
        rpName,
        sessionExpiryMs,
        signatureExpirationLedgers,
        timeoutInSeconds,
        relayerUrl,
        indexerUrl,
        webauthnProvider,
        storage,
        externalWallet,
        identityHashCode(externalSignerManager),
        maxContextRuleScanId,
      ]);
}

/// Builder for constructing [OZSmartAccountConfig] with a fluent API.
///
/// Example:
///
/// ```dart
/// final config = OZSmartAccountConfig.builder(
///   rpcUrl: 'https://soroban-testnet.stellar.org',
///   networkPassphrase: 'Test SDF Network ; September 2015',
///   accountWasmHash: 'abc123...',
///   webauthnVerifierAddress: 'CBCD1234...',
/// )
///     .rpName('My Wallet')
///     .sessionExpiryMs(86400000)
///     .build();
/// ```
class OZSmartAccountConfigBuilder {
  /// Constructs a builder with the four required configuration fields.
  OZSmartAccountConfigBuilder({
    required String rpcUrl,
    required String networkPassphrase,
    required String accountWasmHash,
    required String webauthnVerifierAddress,
  })  : _rpcUrl = rpcUrl,
        _networkPassphrase = networkPassphrase,
        _accountWasmHash = accountWasmHash,
        _webauthnVerifierAddress = webauthnVerifierAddress;

  final String _rpcUrl;
  final String _networkPassphrase;
  final String _accountWasmHash;
  final String _webauthnVerifierAddress;
  KeyPair? _deployerKeypair;
  String? _rpId;
  String _rpName = 'Smart Account';
  int _sessionExpiryMs = OZConstants.defaultSessionExpiryMs;
  int _signatureExpirationLedgers = Util.ledgersPerHour;
  int _timeoutInSeconds = OZConstants.defaultTimeoutSeconds;
  String? _relayerUrl;
  String? _indexerUrl;
  WebAuthnProvider? _webauthnProvider;
  StorageAdapter? _storage;
  ExternalWalletAdapter? _externalWallet;
  OZExternalSignerManager? _externalSignerManager;
  int _maxContextRuleScanId = 50;

  /// Sets the deployer keypair. Pass `null` to use the deterministic
  /// default.
  OZSmartAccountConfigBuilder deployerKeypair(KeyPair? value) {
    _deployerKeypair = value;
    return this;
  }

  /// Sets the WebAuthn Relying Party ID. Pass `null` to use the browser
  /// default.
  OZSmartAccountConfigBuilder rpId(String? value) {
    _rpId = value;
    return this;
  }

  /// Sets the WebAuthn Relying Party name.
  OZSmartAccountConfigBuilder rpName(String value) {
    _rpName = value;
    return this;
  }

  /// Sets the session expiry in milliseconds.
  OZSmartAccountConfigBuilder sessionExpiryMs(int value) {
    _sessionExpiryMs = value;
    return this;
  }

  /// Sets the signature expiration in ledgers.
  OZSmartAccountConfigBuilder signatureExpirationLedgers(int value) {
    _signatureExpirationLedgers = value;
    return this;
  }

  /// Sets the operation timeout in seconds.
  OZSmartAccountConfigBuilder timeoutInSeconds(int value) {
    _timeoutInSeconds = value;
    return this;
  }

  /// Sets the relayer URL. Pass `null` to disable.
  OZSmartAccountConfigBuilder relayerUrl(String? value) {
    _relayerUrl = value;
    return this;
  }

  /// Sets the indexer URL. Pass `null` to disable.
  OZSmartAccountConfigBuilder indexerUrl(String? value) {
    _indexerUrl = value;
    return this;
  }

  /// Sets the WebAuthn provider. Pass `null` to disable passkey support.
  OZSmartAccountConfigBuilder webauthnProvider(WebAuthnProvider? value) {
    _webauthnProvider = value;
    return this;
  }

  /// Sets the storage adapter for persisting credentials and sessions.
  OZSmartAccountConfigBuilder storage(StorageAdapter value) {
    _storage = value;
    return this;
  }

  /// Sets the external wallet adapter. Pass `null` to disable external
  /// signing.
  OZSmartAccountConfigBuilder externalWallet(ExternalWalletAdapter? value) {
    _externalWallet = value;
    return this;
  }

  /// Sets the external-signer manager for Ed25519 multi-signer signing
  /// ceremonies. Pass `null` to disable Ed25519 multi-signer support.
  OZSmartAccountConfigBuilder externalSignerManager(
      OZExternalSignerManager? value) {
    _externalSignerManager = value;
    return this;
  }

  /// Sets the maximum context rule ID to scan when iterating rules.
  OZSmartAccountConfigBuilder maxContextRuleScanId(int value) {
    _maxContextRuleScanId = value;
    return this;
  }

  /// Builds the [OZSmartAccountConfig], running constructor validation.
  ///
  /// Throws [ConfigurationException] when validation fails.
  OZSmartAccountConfig build() {
    return OZSmartAccountConfig(
      rpcUrl: _rpcUrl,
      networkPassphrase: _networkPassphrase,
      accountWasmHash: _accountWasmHash,
      webauthnVerifierAddress: _webauthnVerifierAddress,
      deployerKeypair: _deployerKeypair,
      rpId: _rpId,
      rpName: _rpName,
      sessionExpiryMs: _sessionExpiryMs,
      signatureExpirationLedgers: _signatureExpirationLedgers,
      timeoutInSeconds: _timeoutInSeconds,
      relayerUrl: _relayerUrl,
      indexerUrl: _indexerUrl,
      webauthnProvider: _webauthnProvider,
      storage: _storage,
      externalWallet: _externalWallet,
      externalSignerManager: _externalSignerManager,
      maxContextRuleScanId: _maxContextRuleScanId,
    );
  }
}

