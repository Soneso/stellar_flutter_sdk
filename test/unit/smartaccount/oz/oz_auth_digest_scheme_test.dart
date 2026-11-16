// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_auth_digest_scheme.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_pipeline_fixtures.dart';

// Selection of the auth digest scheme: the configured and built-in tables,
// the instance read of the wallet's code, and the once-per-operation
// preparation both signing pipelines share.

const String _wallet =
    'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';
const String _otherContract =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';
const String _verifier =
    'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY';
const String _account =
    'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ';

final String _ownHash = '1f' * 32;
final String _unmappedHash = '0' * 64;

OZSmartAccountConfig _config({
  Map<String, OZAuthDigestScheme> authDigestSchemes =
      const <String, OZAuthDigestScheme>{},
  int signatureExpirationLedgers = 720,
}) => OZSmartAccountConfig(
  rpcUrl: 'https://soroban-testnet.stellar.org',
  networkPassphrase: Network.TESTNET.networkPassphrase,
  accountWasmHash: 'a${'0' * 63}',
  webauthnVerifierAddress: _verifier,
  signatureExpirationLedgers: signatureExpirationLedgers,
  authDigestSchemes: authDigestSchemes,
);

XdrContractExecutable _wasm(String hex) =>
    XdrContractExecutable.forWasm(Util.hexToBytes(hex));

/// An auth entry of [address] over a no-op call, with [credentialsType]
/// credentials.
XdrSorobanAuthorizationEntry _entry(
  String address, {
  XdrSorobanCredentialsType credentialsType =
      XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS,
}) {
  final invocation = XdrSorobanAuthorizedInvocation(
    XdrSorobanAuthorizedFunction.forInvokeContractArgs(
      XdrInvokeContractArgs(
        XdrSCAddress.forContractId(_otherContract),
        'noop',
        const <XdrSCVal>[],
      ),
    ),
    <XdrSorobanAuthorizedInvocation>[],
  );
  final scAddress = address.startsWith('C')
      ? XdrSCAddress.forContractId(address)
      : XdrSCAddress.forAccountId(address);
  final inner = XdrSorobanAddressCredentials(
    scAddress,
    XdrInt64(BigInt.one),
    XdrUint32(0),
    XdrSCVal.forVoid(),
  );
  final XdrSorobanCredentials credentials;
  if (credentialsType ==
      XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2) {
    credentials = XdrSorobanCredentials.forAddressV2Credentials(inner);
  } else if (credentialsType ==
      XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES) {
    credentials = XdrSorobanCredentials(credentialsType)
      ..addressWithDelegates = XdrSorobanAddressCredentialsWithDelegates(
        inner,
        <XdrSorobanDelegateSignature>[],
      );
  } else {
    credentials = XdrSorobanCredentials.forAddressCredentials(inner);
  }
  return XdrSorobanAuthorizationEntry(credentials, invocation);
}

XdrSorobanAuthorizationEntry _sourceAccountEntry() =>
    XdrSorobanAuthorizationEntry(
      XdrSorobanCredentials.forSourceAccount(),
      _entry(_wallet).rootInvocation,
    );

/// A wallet entry whose root invocation adds a Delegated contract signer to
/// the wallet.
XdrSorobanAuthorizationEntry _entryAddingContractDelegate() {
  final entry = _entry(_wallet);
  return XdrSorobanAuthorizationEntry(
    entry.credentials,
    XdrSorobanAuthorizedInvocation(
      XdrSorobanAuthorizedFunction.forInvokeContractArgs(
        XdrInvokeContractArgs(
          XdrSCAddress.forContractId(_wallet),
          'add_signer',
          <XdrSCVal>[
            XdrSCVal.forU32(0),
            XdrSCVal.forVec(<XdrSCVal>[
              XdrSCVal.forSymbol('Delegated'),
              XdrSCVal.forContractAddress(_otherContract),
            ]),
          ],
        ),
      ),
      <XdrSorobanAuthorizedInvocation>[],
    ),
  );
}

GetLatestLedgerResponse _latestLedger(int? sequence) =>
    GetLatestLedgerResponse(<String, dynamic>{})..sequence = sequence;

GetLedgerEntriesResponse _entriesWith(
  XdrLedgerEntryData data, {
  int latestLedger = 1000,
}) => GetLedgerEntriesResponse(<String, dynamic>{})
  ..entries = <LedgerEntry>[
    LedgerEntry('', data.toBase64EncodedXdrString(), latestLedger, null, null),
  ]
  ..latestLedger = latestLedger;

({FakePipelineKit kit, MockSorobanServer soroban}) _kit({
  Map<String, OZAuthDigestScheme> authDigestSchemes =
      const <String, OZAuthDigestScheme>{},
  int signatureExpirationLedgers = 720,
}) {
  final soroban = MockSorobanServer();
  final kit = FakePipelineKit(
    config: _config(
      authDigestSchemes: authDigestSchemes,
      signatureExpirationLedgers: signatureExpirationLedgers,
    ),
    sorobanServer: soroban,
  );
  return (kit: kit, soroban: soroban);
}

Future<OZSigningOperationState> _prepareWalletEntry(
  ({FakePipelineKit kit, MockSorobanServer soroban}) h,
) => ozPrepareSigningOperation(h.kit, _wallet, <XdrSorobanAuthorizationEntry>[
  _entry(_wallet),
]);

void main() {
  group('scheme tables', () {
    test('the built-in 0.8.0 build is preimageV1 in any case', () {
      expect(
        _config().authDigestSchemeFor(v080AccountWasmHash),
        OZAuthDigestScheme.preimageV1,
      );
      expect(
        _config().authDigestSchemeFor(v080AccountWasmHash.toUpperCase()),
        OZAuthDigestScheme.preimageV1,
      );
    });

    test('an unmapped hash is legacyConcat', () {
      expect(
        _config().authDigestSchemeFor(_unmappedHash),
        OZAuthDigestScheme.legacyConcat,
      );
      expect(
        _config().authDigestSchemeFor(_ownHash),
        OZAuthDigestScheme.legacyConcat,
      );
    });

    test('a configured own build is preimageV1 in any case', () {
      final config = _config(
        authDigestSchemes: <String, OZAuthDigestScheme>{
          _ownHash.toUpperCase(): OZAuthDigestScheme.preimageV1,
        },
      );
      expect(
        config.authDigestSchemeFor(_ownHash),
        OZAuthDigestScheme.preimageV1,
      );
      expect(
        config.authDigestSchemeFor(_ownHash.toUpperCase()),
        OZAuthDigestScheme.preimageV1,
      );
      expect(
        config.authDigestSchemeFor(v080AccountWasmHash),
        OZAuthDigestScheme.preimageV1,
        reason: 'The built-in entry stays',
      );
    });

    test('a configured entry overrides the built-in build', () {
      final config = _config(
        authDigestSchemes: <String, OZAuthDigestScheme>{
          v080AccountWasmHash: OZAuthDigestScheme.legacyConcat,
        },
      );
      expect(
        config.authDigestSchemeFor(v080AccountWasmHash),
        OZAuthDigestScheme.legacyConcat,
      );
    });

    test('an invalid key throws at construction naming it', () {
      for (final key in <String>[
        '',
        'abc',
        '0' * 63,
        '0' * 65,
        'g' * 64,
        '0x${'0' * 62}',
      ]) {
        expect(
          () => _config(
            authDigestSchemes: <String, OZAuthDigestScheme>{
              key: OZAuthDigestScheme.preimageV1,
            },
          ),
          throwsA(
            isA<SmartAccountInvalidConfig>().having(
              (e) => e.message,
              'message',
              'Invalid configuration: authDigestSchemes key must be a '
                  '64-character hex string (SHA-256 of WASM), got: $key',
            ),
          ),
        );
      }
    });

    test('keys that differ only in case must agree', () {
      expect(
        () => _config(
          authDigestSchemes: <String, OZAuthDigestScheme>{
            _ownHash: OZAuthDigestScheme.preimageV1,
            _ownHash.toUpperCase(): OZAuthDigestScheme.legacyConcat,
          },
        ),
        throwsA(
          isA<SmartAccountInvalidConfig>().having(
            (e) => e.message,
            'message',
            'Invalid configuration: authDigestSchemes maps $_ownHash to both '
                'preimageV1 and legacyConcat',
          ),
        ),
      );

      final agreeing = _config(
        authDigestSchemes: <String, OZAuthDigestScheme>{
          _ownHash: OZAuthDigestScheme.preimageV1,
          _ownHash.toUpperCase(): OZAuthDigestScheme.preimageV1,
        },
      );
      expect(
        agreeing.authDigestSchemeFor(_ownHash),
        OZAuthDigestScheme.preimageV1,
      );
    });

    test('the configured map is a read-only copy of the argument', () {
      final schemes = <String, OZAuthDigestScheme>{
        _ownHash: OZAuthDigestScheme.preimageV1,
      };
      final config = _config(authDigestSchemes: schemes);
      schemes[_ownHash] = OZAuthDigestScheme.legacyConcat;

      expect(config.authDigestSchemes, <String, OZAuthDigestScheme>{
        _ownHash: OZAuthDigestScheme.preimageV1,
      });
      expect(
        config.authDigestSchemeFor(_ownHash),
        OZAuthDigestScheme.preimageV1,
      );
      expect(
        () => config.authDigestSchemes[_ownHash] =
            OZAuthDigestScheme.legacyConcat,
        throwsUnsupportedError,
      );
    });

    test('copyWith, equality and the builder carry the map', () {
      final schemes = <String, OZAuthDigestScheme>{
        _ownHash: OZAuthDigestScheme.preimageV1,
      };
      final config = _config(authDigestSchemes: schemes);

      expect(_config().authDigestSchemes, isEmpty);
      expect(config.copyWith().authDigestSchemes, schemes);
      expect(config.copyWith(), config);
      expect(config.copyWith().hashCode, config.hashCode);
      expect(
        config.copyWith(
          authDigestSchemes: const <String, OZAuthDigestScheme>{},
        ),
        isNot(config),
      );
      expect(config, isNot(_config()));
      expect(config.hashCode, isNot(_config().hashCode));
      expect(
        config.copyWith(maxContextRuleScanId: 5).authDigestSchemeFor(_ownHash),
        OZAuthDigestScheme.preimageV1,
      );

      final built = OZSmartAccountConfig.builder(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: 'a${'0' * 63}',
        webauthnVerifierAddress: _verifier,
      ).authDigestSchemes(schemes).build();
      expect(built.authDigestSchemes, schemes);
      expect(
        built.authDigestSchemeFor(_ownHash),
        OZAuthDigestScheme.preimageV1,
      );
      expect(built, config.copyWith(signatureExpirationLedgers: 720));
    });
  });

  group('instance read', () {
    test('reads the persistent instance of the wallet once', () async {
      final h = _kit();
      h.soroban.ledgerEntriesResponses.add(
        walletInstanceLedgerEntries(
          _wallet,
          executable: _wasm(v080AccountWasmHash),
          latestLedger: 4242,
        ),
      );

      final state = await _prepareWalletEntry(h);

      expect(state.authDigestScheme, OZAuthDigestScheme.preimageV1);
      expect(state.expirationLedger, 4242 + 720);
      expect(h.soroban.ledgerEntriesCalls, hasLength(1));
      expect(h.soroban.latestLedgerCallCount, 0);
      final keys = h.soroban.ledgerEntriesCalls.single;
      expect(keys, hasLength(1));
      final key = XdrLedgerKey.fromBase64EncodedXdrString(keys.single);
      expect(key.discriminant, XdrLedgerEntryType.CONTRACT_DATA);
      expect(key.contractData!.contract.toStrKey(), _wallet);
      expect(
        key.contractData!.key.discriminant,
        XdrSCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE,
      );
      expect(
        key.contractData!.durability,
        XdrContractDataDurability.PERSISTENT,
      );
    });

    test('a configured hash follows the config in both directions', () async {
      final own = _kit(
        authDigestSchemes: <String, OZAuthDigestScheme>{
          _ownHash: OZAuthDigestScheme.preimageV1,
        },
      );
      own.soroban.ledgerEntriesResponses.add(
        walletInstanceLedgerEntries(_wallet, executable: _wasm(_ownHash)),
      );
      expect(
        (await _prepareWalletEntry(own)).authDigestScheme,
        OZAuthDigestScheme.preimageV1,
      );

      final overridden = _kit(
        authDigestSchemes: <String, OZAuthDigestScheme>{
          v080AccountWasmHash: OZAuthDigestScheme.legacyConcat,
        },
      );
      overridden.soroban.ledgerEntriesResponses.add(
        walletInstanceLedgerEntries(
          _wallet,
          executable: _wasm(v080AccountWasmHash),
        ),
      );
      expect(
        (await _prepareWalletEntry(overridden)).authDigestScheme,
        OZAuthDigestScheme.legacyConcat,
      );
    });

    test('an unmapped hash signs legacyConcat', () async {
      final h = _kit();
      h.soroban.ledgerEntriesResponses.add(
        walletInstanceLedgerEntries(_wallet, executable: _wasm(_unmappedHash)),
      );
      expect(
        (await _prepareWalletEntry(h)).authDigestScheme,
        OZAuthDigestScheme.legacyConcat,
      );
    });

    test('an external reference executable signs legacyConcat', () async {
      final h = _kit(
        authDigestSchemes: <String, OZAuthDigestScheme>{
          v080AccountWasmHash: OZAuthDigestScheme.preimageV1,
        },
      );
      h.soroban.ledgerEntriesResponses.add(
        walletInstanceLedgerEntries(
          _wallet,
          executable: XdrContractExecutable.forExternalRef(
            XdrSCAddress.forContractId(_otherContract),
            'account-v1',
          ),
        ),
      );
      expect(
        (await _prepareWalletEntry(h)).authDigestScheme,
        OZAuthDigestScheme.legacyConcat,
      );
    });

    test('a Stellar Asset executable signs legacyConcat', () async {
      final h = _kit();
      h.soroban.ledgerEntriesResponses.add(
        walletInstanceLedgerEntries(
          _wallet,
          executable: XdrContractExecutable.forAsset(),
        ),
      );
      expect(
        (await _prepareWalletEntry(h)).authDigestScheme,
        OZAuthDigestScheme.legacyConcat,
      );
    });

    test('a missing instance entry signs legacyConcat at the reported '
        'ledger', () async {
      final h = _kit();
      h.soroban.ledgerEntriesResponses.add(
        GetLedgerEntriesResponse(<String, dynamic>{})
          ..entries = <LedgerEntry>[]
          ..latestLedger = 321,
      );
      final state = await _prepareWalletEntry(h);
      expect(state.authDigestScheme, OZAuthDigestScheme.legacyConcat);
      expect(state.expirationLedger, 321 + 720);
    });

    test('a response without an entry list signs legacyConcat', () async {
      final h = _kit();
      h.soroban.ledgerEntriesResponses.add(
        GetLedgerEntriesResponse(<String, dynamic>{})..latestLedger = 55,
      );
      final state = await _prepareWalletEntry(h);
      expect(state.authDigestScheme, OZAuthDigestScheme.legacyConcat);
      expect(state.expirationLedger, 55 + 720);
    });

    test(
      'an RPC error response throws naming the wallet and the error',
      () async {
        final h = _kit();
        h.soroban.ledgerEntriesResponses.add(
          GetLedgerEntriesResponse.fromJson(<String, dynamic>{
            'jsonrpc': '2.0',
            'id': 1,
            'error': <String, dynamic>{
              'code': -32603,
              'message': 'instance read failed',
            },
          }),
        );
        await expectLater(
          _prepareWalletEntry(h),
          throwsA(
            isA<SmartAccountTransactionSubmissionFailed>().having(
              (e) => e.message,
              'message',
              'Transaction submission failed: Failed to read the instance of '
                  '$_wallet to select its auth digest scheme: RPC error '
                  '-32603: instance read failed',
            ),
          ),
        );
        expect(h.soroban.latestLedgerCallCount, 0);
      },
    );

    test('a response without a latest ledger throws', () async {
      final h = _kit();
      h.soroban.ledgerEntriesResponses.add(
        GetLedgerEntriesResponse(<String, dynamic>{})
          ..entries = <LedgerEntry>[],
      );
      await expectLater(
        _prepareWalletEntry(h),
        throwsA(
          isA<SmartAccountTransactionSubmissionFailed>().having(
            (e) => e.message,
            'message',
            'Transaction submission failed: The instance read of $_wallet '
                'reported no latest ledger',
          ),
        ),
      );
    });

    test('a ledger entry that is no contract data throws', () async {
      final h = _kit();
      final ttl = XdrLedgerEntryData(XdrLedgerEntryType.TTL)
        ..ttl = XdrTTLEntry(XdrHash(Uint8List(32)), XdrUint32(9));
      h.soroban.ledgerEntriesResponses.add(_entriesWith(ttl));
      await expectLater(
        _prepareWalletEntry(h),
        throwsA(
          isA<SmartAccountTransactionSigningFailed>().having(
            (e) => e.message,
            'message',
            'Transaction signing failed: The instance entry of $_wallet is '
                'not a contract instance (TTL)',
          ),
        ),
      );
    });

    test('contract data that is no instance throws', () async {
      final h = _kit();
      final contractData = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_DATA)
        ..contractData = XdrContractDataEntry(
          XdrExtensionPoint(0),
          XdrSCAddress.forContractId(_wallet),
          XdrSCVal.forLedgerKeyContractInstance(),
          XdrContractDataDurability.PERSISTENT,
          XdrSCVal.forU32(7),
        );
      h.soroban.ledgerEntriesResponses.add(_entriesWith(contractData));
      await expectLater(
        _prepareWalletEntry(h),
        throwsA(
          isA<SmartAccountTransactionSigningFailed>().having(
            (e) => e.message,
            'message',
            'Transaction signing failed: The instance entry of $_wallet is '
                'not a contract instance (CONTRACT_DATA)',
          ),
        ),
      );
    });

    test('an undecodable entry throws naming the wallet', () async {
      final h = _kit();
      h.soroban.ledgerEntriesResponses.add(
        GetLedgerEntriesResponse(<String, dynamic>{})
          ..entries = <LedgerEntry>[LedgerEntry('', 'AAAA', 1, null, null)]
          ..latestLedger = 1,
      );
      await expectLater(
        _prepareWalletEntry(h),
        throwsA(
          isA<SmartAccountTransactionSigningFailed>().having(
            (e) => e.message,
            'message',
            startsWith(
              'Transaction signing failed: Failed to decode the instance '
              'entry of $_wallet to read its code: ',
            ),
          ),
        ),
      );
    });

    test('an upgrade between two operations changes the scheme', () async {
      final h = _kit();
      h.soroban.ledgerEntriesResponses
        ..add(
          walletInstanceLedgerEntries(
            _wallet,
            executable: _wasm(_unmappedHash),
          ),
        )
        ..add(
          walletInstanceLedgerEntries(
            _wallet,
            executable: _wasm(v080AccountWasmHash),
          ),
        );
      expect(
        (await _prepareWalletEntry(h)).authDigestScheme,
        OZAuthDigestScheme.legacyConcat,
      );
      expect(
        (await _prepareWalletEntry(h)).authDigestScheme,
        OZAuthDigestScheme.preimageV1,
      );
    });
  });

  group('once-per-operation preparation', () {
    test('several wallet entries read the instance once and expire from '
        'its ledger', () async {
      final h = _kit(signatureExpirationLedgers: 17);
      h.soroban.ledgerEntriesResponses.add(
        walletInstanceLedgerEntries(
          _wallet,
          executable: _wasm(v080AccountWasmHash),
          latestLedger: 5000,
        ),
      );

      final state = await ozPrepareSigningOperation(
        h.kit,
        _wallet,
        <XdrSorobanAuthorizationEntry>[
          _entry(_account),
          _entry(_wallet),
          _entry(
            _wallet,
            credentialsType:
                XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
          ),
        ],
      );

      expect(state.authDigestScheme, OZAuthDigestScheme.preimageV1);
      expect(state.expirationLedger, 5017);
      expect(h.soroban.ledgerEntriesCalls, hasLength(1));
      expect(h.soroban.latestLedgerCallCount, 0);
    });

    test('without a wallet entry only the latest ledger is read', () async {
      final h = _kit();
      h.soroban.latestLedgerResponses.add(_latestLedger(7000));

      final state = await ozPrepareSigningOperation(
        h.kit,
        _wallet,
        <XdrSorobanAuthorizationEntry>[
          _entry(_account),
          _sourceAccountEntry(),
          _entry(_otherContract),
          _entry(
            _wallet,
            credentialsType: XdrSorobanCredentialsType
                .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES,
          ),
        ],
      );

      expect(state.authDigestScheme, isNull);
      expect(state.expirationLedger, 7000 + 720);
      expect(h.soroban.ledgerEntriesCalls, isEmpty);
      expect(h.soroban.latestLedgerCallCount, 1);
    });

    test('without a wallet entry a latest ledger without a sequence '
        'throws', () async {
      final h = _kit();
      h.soroban.latestLedgerResponses.add(_latestLedger(null));
      await expectLater(
        ozPrepareSigningOperation(
          h.kit,
          _wallet,
          <XdrSorobanAuthorizationEntry>[_entry(_account)],
        ),
        throwsA(
          isA<SmartAccountTransactionSubmissionFailed>().having(
            (e) => e.message,
            'message',
            'Transaction submission failed: Failed to fetch latest ledger '
                'sequence',
          ),
        ),
      );
    });

    test('a refused added signer throws before any read', () async {
      final h = _kit();
      await expectLater(
        ozPrepareSigningOperation(
          h.kit,
          _wallet,
          <XdrSorobanAuthorizationEntry>[_entryAddingContractDelegate()],
        ),
        throwsA(isA<SmartAccountInvalidAddress>()),
      );
      expect(h.soroban.ledgerEntriesCalls, isEmpty);
      expect(h.soroban.latestLedgerCallCount, 0);
    });
  });
}
