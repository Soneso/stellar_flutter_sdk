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
///     .sessionExpiryMs(86400000)
///     .relayerUrl('https://relayer.example.com')
///     .storage(myPersistentStorage)
///     .externalWallet(freighterAdapter)
///     .build();
/// ```
///
/// Throws [SmartAccountConfigurationException] if required parameters are blank or
/// invalid (e.g. `accountWasmHash` is not a 64-character hex string, or
/// `webauthnVerifierAddress` is not a valid C-address).
class OZSmartAccountConfig {
  /// Constructs a configuration for OpenZeppelin Smart Account operations.
  ///
  /// The required parameters [rpcUrl], [networkPassphrase], [accountWasmHash],
  /// and [webauthnVerifierAddress] are validated in the constructor; all
  /// optional parameters fall back to their documented defaults.
  ///
  /// When [storage] is omitted a fresh [OZInMemoryStorageAdapter] is allocated.
  /// All [OZInMemoryStorageAdapter] instances compare equal so two configs
  /// constructed with identical inputs (including the default storage) are
  /// equal as well.
  OZSmartAccountConfig({
    required this.rpcUrl,
    required this.networkPassphrase,
    required this.accountWasmHash,
    required this.webauthnVerifierAddress,
    this.deployerKeypair,
    this.sessionExpiryMs = OZConstants.defaultSessionExpiryMs,
    this.signatureExpirationLedgers = Util.ledgersPerHour,
    this.timeoutInSeconds = OZConstants.defaultTimeoutSeconds,
    this.relayerUrl,
    this.indexerUrl,
    this.webauthnProvider,
    OZStorageAdapter? storage,
    this.externalWallet,
    this.externalEd25519Adapter,
    this.maxContextRuleScanId = 50,
  }) : storage = storage ?? OZInMemoryStorageAdapter() {
    if (rpcUrl.trim().isEmpty) {
      throw SmartAccountConfigurationException.missingConfig('rpcUrl');
    }
    if (networkPassphrase.trim().isEmpty) {
      throw SmartAccountConfigurationException.missingConfig('networkPassphrase');
    }
    if (accountWasmHash.trim().isEmpty) {
      throw SmartAccountConfigurationException.missingConfig('accountWasmHash');
    }
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(accountWasmHash)) {
      throw SmartAccountConfigurationException.invalidConfig(
        'accountWasmHash must be a 64-character hex string '
        '(SHA-256 of WASM), got: $accountWasmHash',
      );
    }
    if (!StrKey.isValidContractId(webauthnVerifierAddress)) {
      throw SmartAccountConfigurationException.invalidConfig(
        'webauthnVerifierAddress must be a valid contract address '
        '(C...), got: $webauthnVerifierAddress',
      );
    }
    if (maxContextRuleScanId < 0) {
      throw SmartAccountConfigurationException.invalidConfig(
        'maxContextRuleScanId must be non-negative, '
        'got: $maxContextRuleScanId',
      );
    }
    // why: reject zero and negative values — an auth entry with
    // signatureExpirationLedgers < 1 would be immediately expired or invalid
    // before submission. No upper bound is enforced client-side: the maximum
    // is the network's configurable maxEntryTTL (CAP-0046-11), which is not
    // a fixed constant and may change between network upgrades. The host
    // enforces the upper bound at submission and reports an out-of-range
    // expiration ledger as a transaction error.
    if (signatureExpirationLedgers < 1) {
      throw SmartAccountConfigurationException.invalidConfig(
        'signatureExpirationLedgers must be >= 1, '
        'got: $signatureExpirationLedgers',
      );
    }
    // why: reject negative `timeoutInSeconds` only. Zero is a valid value
    // that maps to a transaction max_time of 0 (Stellar's "no upper bound",
    // i.e. the transaction never expires by time); any positive value sets
    // max_time = now + timeoutInSeconds.
    if (timeoutInSeconds < 0) {
      throw SmartAccountConfigurationException.invalidConfig(
        'timeoutInSeconds must be >= 0 (0 means no expiry), '
        'got: $timeoutInSeconds',
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

  /// Session expiry time in milliseconds. Sessions enable silent
  /// reconnection without re-authentication. Default: 604_800_000
  /// (7 days).
  final int sessionExpiryMs;

  /// Signature expiration in ledgers for auth entries. Auth entries expire
  /// after this many ledgers to prevent replay attacks. Default: 720
  /// (about one hour at five seconds per ledger). Must be >= 1.
  final int signatureExpirationLedgers;

  /// Sets each transaction's TimeBounds max_time (min_time is always 0),
  /// bounding how long a signed transaction stays valid for submission.
  ///
  /// A positive value sets `max_time = now + timeoutInSeconds`. A value of
  /// `0` sets `max_time = 0`, which is Stellar's "no upper bound" (the
  /// transaction never expires by time / infinite validity). Must be `>= 0`.
  /// Default: 30.
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
  /// to [OZInMemoryStorageAdapter] (non-persistent, suitable for testing).
  final OZStorageAdapter storage;

  /// External wallet adapter for signing transactions with an external
  /// signer. When set, the kit injects it into the kit-owned
  /// [OZExternalSignerManager] at construction so all wallet-signer
  /// operations route through `kit.externalSigners`.
  final OZExternalWalletAdapter? externalWallet;

  /// Optional adapter for out-of-process Ed25519 signing.
  ///
  /// When set, the kit injects it into the kit-owned
  /// [OZExternalSignerManager] at construction. The adapter is consulted
  /// first (adapter-first precedence) before the in-memory keypair
  /// registry for every [OZSelectedSignerEd25519] entry during multi-signer
  /// operations.
  final OZExternalEd25519SignerAdapter? externalEd25519Adapter;

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
  /// by the contract spec so the resulting account ID is reproducible and
  /// recognisable on-chain. The deployer only pays deployment fees and does
  /// not control user wallets. Suitable for testing and simple deployments;
  /// production apps typically use a custom deployer for attribution and
  /// traceability.
  ///
  /// Throws [SmartAccountConfigurationException] if seed generation fails.
  static Future<KeyPair> createDefaultDeployer() async {
    try {
      // why: this exact UTF-8 byte sequence is the protocol-defined constant
      // for the default deployer seed. Every wallet deployed via the default
      // deployer has a contract address that depends on it; changing this
      // string would orphan all previously deployed wallets.
      const seedString = 'openzeppelin-smart-account-kit';
      final seedBytes = Uint8List.fromList(utf8.encode(seedString));
      final seedHash = Util.hash(seedBytes);
      return KeyPair.fromSecretSeedList(seedHash);
    } catch (e) {
      throw SmartAccountConfigurationException.invalidConfig(
        'Failed to create default deployer keypair: $e',
        cause: e,
      );
    }
  }

  /// Returns a [OZSmartAccountConfigBuilder] for fluent construction. See the
  /// class-level doc for a usage example.
  ///
  /// The four required parameters seed the builder; all optional settings are
  /// applied through the builder's setter methods before [build] runs
  /// constructor validation.
  ///
  /// Parameters:
  ///
  /// - [rpcUrl]: Soroban RPC endpoint URL.
  /// - [networkPassphrase]: Stellar network passphrase.
  /// - [accountWasmHash]: SHA-256 hash of the smart account contract WASM as
  ///   a 64-character hex string.
  /// - [webauthnVerifierAddress]: WebAuthn signature verifier contract
  ///   address (C-address).
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
  /// Throws [SmartAccountConfigurationException] if default deployer creation fails.
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
  /// field. Pass [setDeployerKeypair] / [setRelayerUrl] /
  /// [setIndexerUrl] / [setWebauthnProvider] / [setExternalWallet] /
  /// [setExternalEd25519Adapter] as `true` together with the corresponding
  /// `null` argument to clear an optional field.
  OZSmartAccountConfig copyWith({
    String? rpcUrl,
    String? networkPassphrase,
    String? accountWasmHash,
    String? webauthnVerifierAddress,
    KeyPair? deployerKeypair,
    bool setDeployerKeypair = false,
    int? sessionExpiryMs,
    int? signatureExpirationLedgers,
    int? timeoutInSeconds,
    String? relayerUrl,
    bool setRelayerUrl = false,
    String? indexerUrl,
    bool setIndexerUrl = false,
    WebAuthnProvider? webauthnProvider,
    bool setWebauthnProvider = false,
    OZStorageAdapter? storage,
    OZExternalWalletAdapter? externalWallet,
    bool setExternalWallet = false,
    OZExternalEd25519SignerAdapter? externalEd25519Adapter,
    bool setExternalEd25519Adapter = false,
    int? maxContextRuleScanId,
  }) {
    return OZSmartAccountConfig(
      rpcUrl: rpcUrl ?? this.rpcUrl,
      networkPassphrase: networkPassphrase ?? this.networkPassphrase,
      accountWasmHash: accountWasmHash ?? this.accountWasmHash,
      webauthnVerifierAddress:
          webauthnVerifierAddress ?? this.webauthnVerifierAddress,
      deployerKeypair: setDeployerKeypair ? deployerKeypair : (deployerKeypair ?? this.deployerKeypair),
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
      externalEd25519Adapter: setExternalEd25519Adapter
          ? externalEd25519Adapter
          : (externalEd25519Adapter ?? this.externalEd25519Adapter),
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
        sessionExpiryMs == other.sessionExpiryMs &&
        signatureExpirationLedgers == other.signatureExpirationLedgers &&
        timeoutInSeconds == other.timeoutInSeconds &&
        relayerUrl == other.relayerUrl &&
        indexerUrl == other.indexerUrl &&
        webauthnProvider == other.webauthnProvider &&
        storage == other.storage &&
        externalWallet == other.externalWallet &&
        // why: OZExternalEd25519SignerAdapter is a stateful object; value
        // equality is meaningless. Use identity (identical) so two configs that
        // reference the same adapter instance compare equal, while different
        // instances do not.
        identical(externalEd25519Adapter, other.externalEd25519Adapter) &&
        maxContextRuleScanId == other.maxContextRuleScanId;
  }

  @override
  int get hashCode => Object.hashAll([
        rpcUrl,
        networkPassphrase,
        accountWasmHash,
        webauthnVerifierAddress,
        deployerKeypair,
        sessionExpiryMs,
        signatureExpirationLedgers,
        timeoutInSeconds,
        relayerUrl,
        indexerUrl,
        webauthnProvider,
        storage,
        externalWallet,
        identityHashCode(externalEd25519Adapter),
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
  int _sessionExpiryMs = OZConstants.defaultSessionExpiryMs;
  int _signatureExpirationLedgers = Util.ledgersPerHour;
  int _timeoutInSeconds = OZConstants.defaultTimeoutSeconds;
  String? _relayerUrl;
  String? _indexerUrl;
  WebAuthnProvider? _webauthnProvider;
  OZStorageAdapter? _storage;
  OZExternalWalletAdapter? _externalWallet;
  OZExternalEd25519SignerAdapter? _externalEd25519Adapter;
  int _maxContextRuleScanId = 50;

  /// Sets the deployer keypair. Pass `null` to use the deterministic
  /// default.
  OZSmartAccountConfigBuilder deployerKeypair(KeyPair? value) {
    _deployerKeypair = value;
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
  OZSmartAccountConfigBuilder storage(OZStorageAdapter value) {
    _storage = value;
    return this;
  }

  /// Sets the external wallet adapter. Pass `null` to disable external
  /// signing.
  OZSmartAccountConfigBuilder externalWallet(OZExternalWalletAdapter? value) {
    _externalWallet = value;
    return this;
  }

  /// Sets the Ed25519 adapter for out-of-process Ed25519 signing. Pass
  /// `null` to disable adapter-backed Ed25519 signing.
  OZSmartAccountConfigBuilder externalEd25519Adapter(
      OZExternalEd25519SignerAdapter? value) {
    _externalEd25519Adapter = value;
    return this;
  }

  /// Sets the maximum context rule ID to scan when iterating rules.
  OZSmartAccountConfigBuilder maxContextRuleScanId(int value) {
    _maxContextRuleScanId = value;
    return this;
  }

  /// Builds the [OZSmartAccountConfig], running constructor validation.
  ///
  /// Throws [SmartAccountConfigurationException] when validation fails.
  OZSmartAccountConfig build() {
    return OZSmartAccountConfig(
      rpcUrl: _rpcUrl,
      networkPassphrase: _networkPassphrase,
      accountWasmHash: _accountWasmHash,
      webauthnVerifierAddress: _webauthnVerifierAddress,
      deployerKeypair: _deployerKeypair,
      sessionExpiryMs: _sessionExpiryMs,
      signatureExpirationLedgers: _signatureExpirationLedgers,
      timeoutInSeconds: _timeoutInSeconds,
      relayerUrl: _relayerUrl,
      indexerUrl: _indexerUrl,
      webauthnProvider: _webauthnProvider,
      storage: _storage,
      externalWallet: _externalWallet,
      externalEd25519Adapter: _externalEd25519Adapter,
      maxContextRuleScanId: _maxContextRuleScanId,
    );
  }
}

