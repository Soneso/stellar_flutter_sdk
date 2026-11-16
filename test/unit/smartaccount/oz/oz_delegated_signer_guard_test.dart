// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_validation.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'mock_oz_transaction_operations.dart';
import 'oz_pipeline_fixtures.dart';
import 'oz_signing_harness.dart';

// The delegated signer guard (GHSA-jpg9-m7w4-c7wc): a Delegated signer the
// SDK adds, or signs an addition of, must be a Stellar account other than
// the shared default deployer, and never the wallet itself. On the raw path
// the rules apply to the fields as the contract stores them, as the
// smart-account-kit applies them. Signers already on chain are read without
// a check.

const String _wallet = harnessWallet;
const String _otherContract =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';
const String _verifier = harnessWebAuthnVerifier;
const String _account =
    'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ';

/// The SEP-23 muxed account of [_account] with id 0.
const String _muxedAccount =
    'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK';
const String _claimableBalance =
    'BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU';
const String _liquidityPool =
    'LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN';
const String _muxedContract =
    'WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAAAWWC';

final Uint8List _passkeyKey = Uint8List.fromList(
  List<int>.generate(65, (i) => i == 0 ? 0x04 : i),
);

Future<String> _defaultDeployer() async =>
    (await OZSmartAccountConfig.createDefaultDeployer()).accountId;

XdrSCVal _delegated(String address) => XdrSCVal.forVec(<XdrSCVal>[
  XdrSCVal.forSymbol('Delegated'),
  XdrSCVal.forAddressStrKey(address),
]);

XdrSCVal _external(Uint8List keyData, {String verifier = _verifier}) =>
    XdrSCVal.forVec(<XdrSCVal>[
      XdrSCVal.forSymbol('External'),
      XdrSCVal.forAddressStrKey(verifier),
      XdrSCVal.forBytes(keyData),
    ]);

({String target, String functionName, List<XdrSCVal> args}) _addSigner(
  XdrSCVal signer, {
  String target = _wallet,
}) => (
  target: target,
  functionName: 'add_signer',
  args: <XdrSCVal>[XdrSCVal.forU32(0), signer],
);

({String target, String functionName, List<XdrSCVal> args}) _batchAddSigner(
  List<XdrSCVal> signers,
) => (
  target: _wallet,
  functionName: 'batch_add_signer',
  args: <XdrSCVal>[XdrSCVal.forU32(0), XdrSCVal.forVec(signers)],
);

({String target, String functionName, List<XdrSCVal> args}) _addContextRule(
  XdrSCVal signers,
) => (
  target: _wallet,
  functionName: 'add_context_rule',
  args: <XdrSCVal>[
    const OZContextRuleTypeDefault().toScVal(),
    XdrSCVal.forString('rule'),
    XdrSCVal.forVoid(),
    signers,
    XdrSCVal.forMap(<XdrSCMapEntry>[]),
  ],
);

XdrSorobanAuthorizedInvocation _invocation(
  ({String target, String functionName, List<XdrSCVal> args}) call, [
  List<XdrSorobanAuthorizedInvocation> subInvocations =
      const <XdrSorobanAuthorizedInvocation>[],
]) => XdrSorobanAuthorizedInvocation(
  XdrSorobanAuthorizedFunction.forInvokeContractArgs(
    XdrInvokeContractArgs(
      XdrSCAddress.forContractId(call.target),
      call.functionName,
      call.args,
    ),
  ),
  subInvocations,
);

/// A wallet entry whose root invocation is [call].
XdrSorobanAuthorizationEntry _entry(
  ({String target, String functionName, List<XdrSCVal> args}) call,
) => harnessEntry(
  target: call.target,
  functionName: call.functionName,
  args: call.args,
);

/// A wallet entry whose root call to [_otherContract] reaches [call]
/// through a nested sub-invocation.
XdrSorobanAuthorizationEntry _nestedEntry(
  ({String target, String functionName, List<XdrSCVal> args}) call,
) => harnessEntry(
  target: _otherContract,
  functionName: 'execute',
  subInvocations: <XdrSorobanAuthorizedInvocation>[
    _invocation(
      (target: _otherContract, functionName: 'route', args: <XdrSCVal>[]),
      <XdrSorobanAuthorizedInvocation>[_invocation(call)],
    ),
  ],
);

Future<void> _guard(XdrSorobanAuthorizationEntry entry) =>
    requireValidAddedSigners(entry, _wallet);

Matcher _invalidInput(Object message) => throwsA(
  isA<SmartAccountInvalidInput>().having((e) => e.message, 'message', message),
);

Matcher _invalidAddress(Object message) => throwsA(
  isA<SmartAccountInvalidAddress>().having(
    (e) => e.message,
    'message',
    message,
  ),
);

String _notAnAccount(String address) =>
    'A delegated signer must be a Stellar account (G-address), got: '
    '$address. Delegating to a contract can let anyone authorize the '
    'account.';

String _unsupportedType(String field, String address) =>
    'Invalid input for signer: $field has an unsupported address type: '
    'SC_ADDRESS_TYPE_MUXED_CONTRACT, got: $address';

void main() {
  group('requireValidAddedSigners', () {
    test('a raw add_signer of a contract delegate is refused naming it', () {
      expect(
        _guard(_entry(_addSigner(_delegated(_otherContract)))),
        _invalidAddress(_notAnAccount(_otherContract)),
      );
    });

    test('the wallet as its own delegate is refused', () {
      expect(
        _guard(_entry(_addSigner(_delegated(_wallet)))),
        _invalidInput(
          'Invalid input for signer: The smart account $_wallet cannot be '
          'its own delegated signer',
        ),
      );
    });

    test('the shared default deployer is refused naming it', () async {
      final deployer = await _defaultDeployer();
      await expectLater(
        _guard(_entry(_addSigner(_delegated(deployer)))),
        _invalidInput(
          'Invalid input for signer: The shared default deployer $deployer '
          'cannot be a delegated signer: its secret derives from a public '
          'string, so anyone could authorize the account through it',
        ),
      );
    });

    test('an account delegate and an External signer pass', () async {
      await _guard(_entry(_addSigner(_delegated(_account))));
      await _guard(_entry(_addSigner(_external(_passkeyKey))));
    });

    test(
      'External key data passes at 256 bytes and is refused at 257',
      () async {
        await _guard(_entry(_addSigner(_external(Uint8List(256)))));
        await expectLater(
          _guard(_entry(_addSigner(_external(Uint8List(257))))),
          _invalidInput(
            'Invalid input for keyData: External signer key data cannot exceed '
            '256 bytes, got: 257',
          ),
        );
      },
    );

    test(
      'a raw batch_add_signer with one contract delegate is refused',
      () async {
        await expectLater(
          _guard(
            _entry(
              _batchAddSigner(<XdrSCVal>[
                _delegated(_account),
                _delegated(_otherContract),
              ]),
            ),
          ),
          _invalidAddress(_notAnAccount(_otherContract)),
        );
        await _guard(
          _entry(
            _batchAddSigner(<XdrSCVal>[
              _delegated(_account),
              _external(_passkeyKey),
            ]),
          ),
        );
      },
    );

    test('the signers argument of a raw add_context_rule is checked', () async {
      await expectLater(
        _guard(
          _entry(
            _addContextRule(
              XdrSCVal.forVec(<XdrSCVal>[_delegated(_otherContract)]),
            ),
          ),
        ),
        _invalidAddress(_notAnAccount(_otherContract)),
      );
      await _guard(
        _entry(
          _addContextRule(XdrSCVal.forVec(<XdrSCVal>[_delegated(_account)])),
        ),
      );
    });

    test(
      'External signers with empty key data pass in every adding call',
      () async {
        final empty = _external(Uint8List(0));
        await _guard(_entry(_addSigner(empty)));
        await _guard(_entry(_batchAddSigner(<XdrSCVal>[empty])));
        await _guard(
          _entry(_addContextRule(XdrSCVal.forVec(<XdrSCVal>[empty]))),
        );
      },
    );

    test('External verifiers of every kind the kit converts pass', () async {
      for (final verifier in <String>[
        _account,
        _verifier,
        _muxedAccount,
        _claimableBalance,
        _liquidityPool,
      ]) {
        await _guard(
          _entry(_addSigner(_external(_passkeyKey, verifier: verifier))),
        );
      }
    });

    test('a muxed account delegate is refused by the account rule', () {
      expect(
        _guard(_entry(_addSigner(_delegated(_muxedAccount)))),
        _invalidAddress(_notAnAccount(_muxedAccount)),
      );
    });

    test('a muxed contract delegate is refused as an unsupported address '
        'type', () {
      expect(
        _guard(_entry(_addSigner(_delegated(_muxedContract)))),
        _invalidInput(
          _unsupportedType('Delegated signer address', _muxedContract),
        ),
      );
    });

    test('a muxed contract verifier is refused in every adding call', () async {
      final signer = _external(_passkeyKey, verifier: _muxedContract);
      for (final call
          in <({String target, String functionName, List<XdrSCVal> args})>[
            _addSigner(signer),
            _batchAddSigner(<XdrSCVal>[signer]),
            _addContextRule(XdrSCVal.forVec(<XdrSCVal>[signer])),
          ]) {
        await expectLater(
          _guard(_entry(call)),
          _invalidInput(
            _unsupportedType(
              'External signer verifier address',
              _muxedContract,
            ),
          ),
        );
      }
    });

    test('an addition nested in a sub-invocation is refused', () {
      expect(
        _guard(_nestedEntry(_addSigner(_delegated(_otherContract)))),
        _invalidAddress(_notAnAccount(_otherContract)),
      );
    });

    test('an addition below a create-contract invocation is refused', () async {
      final preimage =
          XdrContractIDPreimage(
              XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS,
            )
            ..address = XdrSCAddress.forContractId(_wallet)
            ..salt = XdrUint256(Uint8List(32));
      XdrSorobanAuthorizationEntry deploy(
        List<XdrSorobanAuthorizedInvocation> subInvocations,
      ) => XdrSorobanAuthorizationEntry(
        harnessEntry().credentials,
        XdrSorobanAuthorizedInvocation(
          XdrSorobanAuthorizedFunction.forCreateContractArgsV2(
            XdrCreateContractArgsV2(
              preimage,
              XdrContractExecutable.forWasm(Uint8List(32)),
              <XdrSCVal>[],
            ),
          ),
          subInvocations,
        ),
      );

      await _guard(deploy(<XdrSorobanAuthorizedInvocation>[]));
      await expectLater(
        _guard(
          deploy(<XdrSorobanAuthorizedInvocation>[
            _invocation(_addSigner(_delegated(_otherContract))),
          ]),
        ),
        _invalidAddress(_notAnAccount(_otherContract)),
      );
    });

    test('an add_signer on another contract is ignored', () async {
      await _guard(
        _entry(_addSigner(_delegated(_otherContract), target: _otherContract)),
      );
    });

    test('other wallet functions are ignored', () async {
      await _guard(
        _entry((
          target: _wallet,
          functionName: 'remove_signer',
          args: <XdrSCVal>[XdrSCVal.forU32(0), _delegated(_otherContract)],
        )),
      );
    });

    test(
      'a signer list argument that is no Vec is refused naming the call',
      () async {
        await expectLater(
          _guard(
            _entry((
              target: _wallet,
              functionName: 'batch_add_signer',
              args: <XdrSCVal>[XdrSCVal.forU32(0), XdrSCVal.forU32(5)],
            )),
          ),
          _invalidInput(
            'Invalid input for signers: batch_add_signer on $_wallet carries '
            'SCV_U32 at argument 1, where a Vec of signers is expected',
          ),
        );
        await expectLater(
          _guard(_entry(_addContextRule(XdrSCVal.forString('signers')))),
          _invalidInput(
            'Invalid input for signers: add_context_rule on $_wallet carries '
            'SCV_STRING at argument 3, where a Vec of signers is expected',
          ),
        );
      },
    );

    test(
      'a call without its signer argument is left to the contract',
      () async {
        await _guard(
          _entry((
            target: _wallet,
            functionName: 'add_signer',
            args: <XdrSCVal>[XdrSCVal.forU32(0)],
          )),
        );
        await _guard(
          _entry((
            target: _wallet,
            functionName: 'add_context_rule',
            args: <XdrSCVal>[const OZContextRuleTypeDefault().toScVal()],
          )),
        );
      },
    );

    test('a signer Vec without a value counts as empty', () async {
      await _guard(
        _entry((
          target: _wallet,
          functionName: 'batch_add_signer',
          args: <XdrSCVal>[XdrSCVal.forU32(0), XdrSCVal(XdrSCValType.SCV_VEC)],
        )),
      );
    });

    test('a value that is no signer is refused', () async {
      final malformed = <XdrSCVal, String>{
        XdrSCVal.forU32(1): 'Signer ScVal is not a non-empty Vec',
        XdrSCVal.forVec(<XdrSCVal>[]): 'Signer ScVal is not a non-empty Vec',
        XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forU32(1)]):
            'First element of signer Vec is not a Symbol',
        XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forSymbol('Delegated')]):
            'Delegated signer second element is not an Address',
        XdrSCVal.forVec(<XdrSCVal>[
          XdrSCVal.forSymbol('External'),
          XdrSCVal.forContractAddress(_verifier),
        ]): 'External signer Vec must hold an Address and Bytes',
        XdrSCVal.forVec(<XdrSCVal>[
          XdrSCVal.forSymbol('Policy'),
          XdrSCVal.forContractAddress(_verifier),
        ]): "Unknown signer type tag: 'Policy'",
      };
      for (final MapEntry(key: value, value: reason) in malformed.entries) {
        await expectLater(
          _guard(_entry(_addSigner(value))),
          throwsA(
            isA<SmartAccountTransactionSigningFailed>().having(
              (e) => e.message,
              'message',
              'Transaction signing failed: $reason',
            ),
          ),
        );
      }
    });
  });

  group('requireValidSigners', () {
    test('typed Delegated signers follow the same rules', () async {
      final deployer = await _defaultDeployer();
      await requireValidSigners(<OZSmartAccountSigner>[
        OZDelegatedSigner(_account),
      ], _wallet);
      await expectLater(
        requireValidSigners(<OZSmartAccountSigner>[
          OZDelegatedSigner(_otherContract),
        ], _wallet),
        _invalidAddress(_notAnAccount(_otherContract)),
      );
      await expectLater(
        requireValidSigners(<OZSmartAccountSigner>[
          OZDelegatedSigner(_wallet),
        ], _wallet),
        _invalidInput(contains('cannot be its own delegated signer')),
      );
      await expectLater(
        requireValidSigners(<OZSmartAccountSigner>[
          OZDelegatedSigner(deployer),
        ], _wallet),
        _invalidInput(contains(deployer)),
      );
    });
  });

  group('manager entry points', () {
    ({FakePipelineKit kit, MockOZTransactionOperations txOps}) harness() {
      final kit = FakePipelineKit();
      final txOps = MockOZTransactionOperations(kit);
      kit.setTransactionOperations(txOps);
      kit.setConnected(credentialId: 'credential', contractId: _wallet);
      return (kit: kit, txOps: txOps);
    }

    test('addDelegated refuses a contract, the wallet and the default '
        'deployer before any submission', () async {
      final h = harness();
      final manager = OZSignerManager(h.kit);
      final deployer = await _defaultDeployer();
      await expectLater(
        manager.addDelegated(contextRuleId: 0, address: _otherContract),
        _invalidAddress(_notAnAccount(_otherContract)),
      );
      await expectLater(
        manager.addDelegated(contextRuleId: 0, address: _wallet),
        _invalidInput(contains('cannot be its own delegated signer')),
      );
      await expectLater(
        manager.addDelegated(contextRuleId: 0, address: deployer),
        _invalidInput(contains(deployer)),
      );
      expect(h.txOps.submitCalls, isEmpty);
    });

    test('addDelegated submits an account delegate', () async {
      final h = harness();
      final result = await OZSignerManager(
        h.kit,
      ).addDelegated(contextRuleId: 0, address: _account);
      expect(result.success, isTrue);
      expect(h.txOps.submitCalls, hasLength(1));
    });

    test('addContextRule refuses each unsafe delegate before any '
        'submission', () async {
      final h = harness();
      final manager = OZContextRuleManager(h.kit);
      final passkey = OZExternalSigner(_verifier, _passkeyKey);
      for (final refused in <OZSmartAccountSigner>[
        OZDelegatedSigner(_otherContract),
        OZDelegatedSigner(_wallet),
        OZDelegatedSigner(await _defaultDeployer()),
      ]) {
        await expectLater(
          manager.addContextRule(
            contextType: const OZContextRuleTypeDefault(),
            name: 'rule',
            signers: <OZSmartAccountSigner>[passkey, refused],
          ),
          throwsA(isA<SmartAccountValidationException>()),
        );
      }
      expect(h.txOps.submitCalls, isEmpty);
    });

    test('addContextRule submits an account delegate', () async {
      final h = harness();
      final result = await OZContextRuleManager(h.kit).addContextRule(
        contextType: const OZContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_account)],
      );
      expect(result.success, isTrue);
      expect(h.txOps.submitCalls, hasLength(1));
    });
  });

  group('signing pipelines', () {
    /// The raw calls the guard refuses, each with its refusal.
    final refusedCalls =
        <
          String,
          (
            Future<XdrSorobanAuthorizationEntry> Function(),
            Matcher Function(String deployer),
          )
        >{
          'add_signer of a contract delegate': (
            () async => _entry(_addSigner(_delegated(_otherContract))),
            (_) => isA<SmartAccountInvalidAddress>(),
          ),
          'batch_add_signer of the default deployer': (
            () async => _entry(
              _batchAddSigner(<XdrSCVal>[_delegated(await _defaultDeployer())]),
            ),
            (deployer) => isA<SmartAccountInvalidInput>().having(
              (e) => e.message,
              'message',
              contains(deployer),
            ),
          ),
          'nested add_context_rule of a contract delegate': (
            () async => _nestedEntry(
              _addContextRule(
                XdrSCVal.forVec(<XdrSCVal>[_delegated(_otherContract)]),
              ),
            ),
            (_) => isA<SmartAccountInvalidAddress>(),
          ),
          'add_signer of a muxed contract delegate': (
            () async => _entry(_addSigner(_delegated(_muxedContract))),
            (_) => isA<SmartAccountInvalidInput>(),
          ),
          'add_signer of a muxed contract verifier': (
            () async => _entry(
              _addSigner(_external(_passkeyKey, verifier: _muxedContract)),
            ),
            (_) => isA<SmartAccountInvalidInput>(),
          ),
        };

    /// The raw additions the contract and the kit accept.
    final acceptedCalls = <String, XdrSorobanAuthorizationEntry Function()>{
      'add_signer of empty External key data': () =>
          _entry(_addSigner(_external(Uint8List(0)))),
      'batch_add_signer of empty External key data': () =>
          _entry(_batchAddSigner(<XdrSCVal>[_external(Uint8List(0))])),
      'add_context_rule of empty External key data': () => _entry(
        _addContextRule(XdrSCVal.forVec(<XdrSCVal>[_external(Uint8List(0))])),
      ),
      'add_signer of an account verifier': () =>
          _entry(_addSigner(_external(_passkeyKey, verifier: _account))),
      'add_signer of a muxed account verifier': () =>
          _entry(_addSigner(_external(_passkeyKey, verifier: _muxedAccount))),
      'add_signer of a claimable balance verifier': () => _entry(
        _addSigner(_external(_passkeyKey, verifier: _claimableBalance)),
      ),
      'add_signer of a liquidity pool verifier': () =>
          _entry(_addSigner(_external(_passkeyKey, verifier: _liquidityPool))),
      'add_signer of an account delegate': () =>
          _entry(_addSigner(_delegated(_account))),
    };

    for (final MapEntry(key: name, value: (build, refusal))
        in refusedCalls.entries) {
      test('submit refuses a raw $name after an accepted wallet entry, '
          'before any passkey or read', () async {
        final deployer = await _defaultDeployer();
        final run = await runSingleSignerSubmit(<XdrSorobanAuthorizationEntry>[
          _entry(_addSigner(_delegated(_account))),
          await build(),
        ], harnessInstanceRead(v080Executable()));

        expect(run.error, refusal(deployer));
        expect(run.provider.authenticateCalls, isEmpty);
        expect(run.server.ledgerEntriesCalls, isEmpty);
        expect(run.server.sendCalls, isEmpty);
      });

      test('submitWithMultipleSigners refuses a raw $name after a foreign '
          'and an accepted wallet entry, before any signer or read', () async {
        final deployer = await _defaultDeployer();
        final entry = await build();
        final run = await runMultiSignerSubmit(
          (walletSigner) => <XdrSorobanAuthorizationEntry>[
            harnessEntry(address: walletSigner, target: _otherContract),
            _entry(_addSigner(_delegated(_account))),
            entry,
          ],
          harnessInstanceRead(v080Executable()),
          withWalletSigner: true,
        );

        expect(run.error, refusal(deployer));
        expect(run.wallet.preimages, isEmpty);
        expect(run.ed25519.digests, isEmpty);
        expect(run.server.ledgerEntriesCalls, isEmpty);
        expect(run.server.sendCalls, isEmpty);
      });
    }

    for (final MapEntry(key: name, value: build) in acceptedCalls.entries) {
      test('submit signs a raw $name', () async {
        final run = await runSingleSignerSubmit(<XdrSorobanAuthorizationEntry>[
          build(),
        ], harnessInstanceRead(v080Executable()));

        expect(run.error, isNull);
        expect(run.result!.success, isTrue);
        expect(run.challenges, hasLength(1));
      });

      test('submitWithMultipleSigners signs a raw $name', () async {
        final run = await runMultiSignerSubmit(
          (_) => <XdrSorobanAuthorizationEntry>[build()],
          harnessInstanceRead(v080Executable()),
        );

        expect(run.error, isNull);
        expect(run.result!.success, isTrue);
        expect(run.ed25519.digests, hasLength(1));
      });
    }
  });

  group('reads stay open', () {
    test('a listed rule with a contract delegate parses', () {
      XdrSCMapEntry field(String key, XdrSCVal value) =>
          XdrSCMapEntry(XdrSCVal.forSymbol(key), value);
      final parsed = OZContextRuleManager(FakePipelineKit()).parseContextRule(
        XdrSCVal.forMap(<XdrSCMapEntry>[
          field('context_type', const OZContextRuleTypeDefault().toScVal()),
          field('id', XdrSCVal.forU32(0)),
          field('name', XdrSCVal.forString('legacy')),
          field('policies', XdrSCVal.forVec(<XdrSCVal>[])),
          field('policy_ids', XdrSCVal.forVec(<XdrSCVal>[])),
          field('signer_ids', XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forU32(0)])),
          field(
            'signers',
            XdrSCVal.forVec(<XdrSCVal>[_delegated(_otherContract)]),
          ),
          field('valid_until', XdrSCVal.forVoid()),
        ]),
      );
      expect(parsed.signers, <OZSmartAccountSigner>[
        OZDelegatedSigner(_otherContract),
      ]);
    });
  });
}
