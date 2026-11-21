// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import '../../key_pair.dart';
import '../../xdr/xdr.dart';
import '../core/smart_account_errors.dart';
import 'oz_address_strkey.dart';
import 'oz_constants.dart';
import 'oz_smart_account_config.dart';
import 'oz_smart_account_types.dart';

/// Validates that [address] is a Stellar contract address (C-address).
///
/// Uses full StrKey validation including the CRC16 checksum.
///
/// Throws an [SmartAccountInvalidAddress] validation exception when [address] is not a
/// valid contract address. The exception message is
/// `"<fieldName> must be a valid contract address (C...), got: <address>"`.
void requireContractAddress(String address, {required String fieldName}) {
  if (!StrKey.isValidContractId(address)) {
    throw SmartAccountInvalidAddress(
      '$fieldName must be a valid contract address (C...), got: $address',
    );
  }
}

/// Returns `true` when [url] is a development localhost URL safe for use as
/// an OZ service endpoint.
///
/// The URL is parsed via [Uri.tryParse] and the resolved host must equal
/// `localhost`, `127.0.0.1`, or `::1` (the IPv6 loopback, which [Uri] strips
/// of its surrounding brackets). Only the `http` scheme is accepted.
///
/// URLs that smuggle a different host through userinfo (for example
/// `http://localhost:8080@evil.com/`, where RFC 3986 parses `localhost:8080`
/// as userinfo and `evil.com` as the host) are rejected by the host check.
/// Any URL that carries userinfo at all is also rejected outright so a
/// parser disagreement between this check and the HTTP client cannot let
/// an attacker-controlled host through.
///
/// Returns `false` for any malformed input, non-HTTP scheme, or non-loopback
/// host.
bool isLocalhostUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return false;
  }
  if (uri.scheme.toLowerCase() != 'http') {
    return false;
  }
  final host = uri.host.toLowerCase();
  if (host != 'localhost' && host != '127.0.0.1' && host != '::1') {
    return false;
  }
  // Even with a loopback host, the presence of userinfo signals a
  // host-confusion attack attempt — reject it outright rather than risk a
  // parser disagreement between this check and the HTTP client below.
  if (uri.userInfo.isNotEmpty) {
    return false;
  }
  return true;
}

/// Validates that [address] is a Stellar account ID (G-address) or a Stellar
/// contract address (C-address).
///
/// Uses full StrKey validation including the CRC16 checksum. Muxed account
/// IDs (M-addresses) are intentionally rejected: callers that need muxed
/// addresses must validate them separately.
///
/// Throws an [SmartAccountInvalidAddress] validation exception when [address] is not a
/// valid Stellar address. The exception message is
/// `"<fieldName> must be a valid Stellar address (G... or C...), got: <address>"`.
void requireStellarAddress(String address, {required String fieldName}) {
  if (!StrKey.isValidStellarAccountId(address) &&
      !StrKey.isValidContractId(address)) {
    throw SmartAccountInvalidAddress(
      '$fieldName must be a valid Stellar address (G... or C...), '
      'got: $address',
    );
  }
}

/// Validates that [targetFn] is a non-blank contract function name.
///
/// Throws a [SmartAccountValidationException] (`invalidInput`) on `targetFn` when the
/// trimmed value is empty.
void requireNonBlankFunctionName(String targetFn) {
  if (targetFn.trim().isEmpty) {
    throw SmartAccountValidationException.invalidInput(
      'targetFn',
      'Function name cannot be empty',
    );
  }
}

/// Validates a context rule name: non-empty and within the OpenZeppelin
/// contract's [OZConstants.maxNameSize]-byte (UTF-8) limit. Rejecting
/// oversized names client-side turns an opaque on-chain failure into a clear
/// error before submission.
///
/// Throws a [SmartAccountValidationException] (`invalidInput`) on `name` when
/// the name is empty or exceeds the byte limit.
void requireValidContextRuleName(String name) {
  if (name.isEmpty) {
    throw SmartAccountValidationException.invalidInput(
      'name',
      'Context rule name cannot be empty',
    );
  }
  final byteLength = utf8.encode(name).length;
  if (byteLength > OZConstants.maxNameSize) {
    throw SmartAccountValidationException.invalidInput(
      'name',
      'Context rule name cannot exceed ${OZConstants.maxNameSize} bytes, '
          'got: $byteLength',
    );
  }
}

/// Validates a policies map (policy contract address -> install
/// parameters): at most [OZConstants.maxPolicies] entries, each keyed by a
/// valid contract address (C...). The map values are the policies' install
/// parameters and are not inspected, so the check performs no encoding
/// work and is safe to run before a passkey ceremony or network access.
///
/// Throws a [SmartAccountValidationException] (`invalidInput`) on
/// `policies` when the map has too many entries, and a
/// [SmartAccountInvalidAddress] validation exception when a key is not a
/// valid contract address.
void requireValidPolicies<V>(Map<String, V> policies) {
  if (policies.length > OZConstants.maxPolicies) {
    throw SmartAccountValidationException.invalidInput(
      'policies',
      'Cannot install more than ${OZConstants.maxPolicies} policies, '
          'got: ${policies.length}',
    );
  }
  for (final address in policies.keys) {
    requireContractAddress(address, fieldName: 'policyAddress');
  }
}

/// Validates signers that are about to be added to the smart account
/// [walletContractId].
///
/// A Delegated signer must be a Stellar account (G-address) other than the
/// shared default deployer ([OZSmartAccountConfig.createDefaultDeployer]). A
/// contract delegate can let anyone authorize the account without a key
/// (GHSA-jpg9-m7w4-c7wc), the wallet itself included, and the default
/// deployer's secret derives from a public string. An External signer's key
/// data must not exceed the OpenZeppelin contract's
/// [OZConstants.maxExternalKeySize]-byte limit.
///
/// Signers already on a wallet are not checked here; reading them never
/// fails on these rules.
///
/// Throws a [SmartAccountValidationException] (`invalidInput`) when a
/// Delegated signer is the default deployer or the wallet itself, or when an
/// External signer's key data is too large, and a
/// [SmartAccountInvalidAddress] validation exception when a Delegated signer
/// is not a G-address.
Future<void> requireValidSigners(
  List<OZSmartAccountSigner> signers,
  String walletContractId,
) async {
  final rules = _AddedSignerRules(walletContractId);
  for (final signer in signers) {
    switch (signer) {
      case OZDelegatedSigner():
        await rules.requireValidDelegate(signer.address);
      case OZExternalSigner():
        _requireExternalKeySize(signer.keyData);
    }
  }
}

/// Wallet functions that add signers, with the index of the argument that
/// holds them and whether that argument is a `Vec` of signers
/// (stellar-accounts 0.8.0 signatures: `add_signer(context_rule_id,
/// signer)`, `batch_add_signer(context_rule_id, signers)`,
/// `add_context_rule(context_type, name, valid_until, signers, policies)`).
const Map<String, ({int index, bool isList})> _signerAddingFunctions =
    <String, ({int index, bool isList})>{
      'add_signer': (index: 1, isList: false),
      'batch_add_signer': (index: 1, isList: true),
      'add_context_rule': (index: 3, isList: true),
    };

/// Validates, with the rules of [requireValidSigners], every signer that an
/// `add_signer`, `batch_add_signer` or `add_context_rule` call on the smart
/// account [walletContractId] adds, anywhere in the invocation tree of
/// [entry].
///
/// The signing pipelines run this over each smart account entry before they
/// ask any signer, so a transaction built from raw contract calls cannot add
/// a Delegated signer that `OZSignerManager.addDelegated` or
/// `OZContextRuleManager.addContextRule` refuses. The rules apply to the
/// fields of each signer value as the contract stores them, without the
/// checks of [OZDelegatedSigner] and [OZExternalSigner]: an External signer
/// with empty key data or with a verifier that is no contract passes, as the
/// contract and the smart-account-kit accept it, while a muxed contract
/// address (W...) as a Delegated address or an External verifier fails, as
/// the kit refuses it. A call without the signer argument is left to the
/// contract, which rejects it.
///
/// Throws a [SmartAccountValidationException] when an added signer fails
/// the rules, or when the signer list argument of `batch_add_signer` or
/// `add_context_rule` is not a `Vec`, and a
/// [SmartAccountTransactionSigningFailed] when an added signer is not a
/// signer value.
Future<void> requireValidAddedSigners(
  XdrSorobanAuthorizationEntry entry,
  String walletContractId,
) async {
  final rules = _AddedSignerRules(walletContractId);
  final pending = Queue<XdrSorobanAuthorizedInvocation>()
    ..add(entry.rootInvocation);
  while (pending.isNotEmpty) {
    final invocation = pending.removeFirst();
    pending.addAll(invocation.subInvocations);

    final call = invocation.function.contractFn;
    if (invocation.function.discriminant !=
            XdrSorobanAuthorizedFunctionType
                .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN ||
        call == null) {
      continue;
    }
    // A name whose bytes are not valid UTF-8 names none of these functions.
    final String? functionName = XdrUtf8.tryDecode(call.functionNameBytes);
    final position = _signerAddingFunctions[functionName];
    if (position == null ||
        OZAddressStrKey.fromXdr(call.contractAddress) != walletContractId ||
        call.args.length <= position.index) {
      continue;
    }

    final argument = call.args[position.index];
    final List<XdrSCVal> signerValues;
    if (!position.isList) {
      signerValues = <XdrSCVal>[argument];
    } else if (argument.discriminant == XdrSCValType.SCV_VEC) {
      signerValues = argument.vec ?? const <XdrSCVal>[];
    } else {
      throw SmartAccountValidationException.invalidInput(
        'signers',
        '$functionName on $walletContractId carries '
            '${argument.discriminant.enumName()} at argument '
            '${position.index}, where a Vec of signers is expected',
      );
    }
    for (final value in signerValues) {
      await _requireValidAddedSignerValue(value, rules);
    }
  }
}

/// Applies the rules of [requireValidSigners] to one raw signer [value],
/// read field by field as the contract stores it.
Future<void> _requireValidAddedSignerValue(
  XdrSCVal value,
  _AddedSignerRules rules,
) async {
  final elements = value.discriminant == XdrSCValType.SCV_VEC
      ? value.vec
      : null;
  if (elements == null || elements.isEmpty) {
    throw SmartAccountTransactionException.signingFailed(
      'Signer ScVal is not a non-empty Vec',
    );
  }
  final tag = elements[0].discriminant == XdrSCValType.SCV_SYMBOL
      ? elements[0].sym
      : null;
  switch (tag) {
    case null:
      throw SmartAccountTransactionException.signingFailed(
        'First element of signer Vec is not a Symbol',
      );
    case 'Delegated':
      final address = elements.length >= 2 ? elements[1].address : null;
      if (address == null) {
        throw SmartAccountTransactionException.signingFailed(
          'Delegated signer second element is not an Address',
        );
      }
      _refuseMuxedContract(address, 'Delegated signer address');
      await rules.requireValidDelegate(address.toStrKey());
    case 'External':
      final verifier = elements.length >= 3 ? elements[1].address : null;
      final keyData = elements.length >= 3 ? elements[2].bytes : null;
      if (verifier == null || keyData == null) {
        throw SmartAccountTransactionException.signingFailed(
          'External signer Vec must hold an Address and Bytes',
        );
      }
      _refuseMuxedContract(verifier, 'External signer verifier address');
      _requireExternalKeySize(keyData.sCBytes);
    default:
      throw SmartAccountTransactionException.signingFailed(
        "Unknown signer type tag: '$tag'",
      );
  }
}

/// Refuses a signer [address] of the muxed contract type (W...), which the
/// smart-account-kit cannot convert to a strkey and refuses; every other
/// address type passes.
void _refuseMuxedContract(XdrSCAddress address, String field) {
  if (address.discriminant == XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_CONTRACT) {
    throw SmartAccountValidationException.invalidInput(
      'signer',
      '$field has an unsupported address type: '
          '${address.discriminant.enumName()}, got: ${address.toStrKey()}',
    );
  }
}

void _requireExternalKeySize(Uint8List keyData) {
  if (keyData.length > OZConstants.maxExternalKeySize) {
    throw SmartAccountValidationException.invalidInput(
      'keyData',
      'External signer key data cannot exceed '
          '${OZConstants.maxExternalKeySize} bytes, '
          'got: ${keyData.length}',
    );
  }
}

/// The Delegated signer rules for one validation pass over signers added to
/// the smart account [walletContractId]; the shared default deployer's
/// address is derived once per pass.
final class _AddedSignerRules {
  _AddedSignerRules(this.walletContractId);

  final String walletContractId;

  String? _defaultDeployerAddress;

  Future<void> requireValidDelegate(String address) async {
    final defaultDeployer = _defaultDeployerAddress ??=
        (await OZSmartAccountConfig.createDefaultDeployer()).accountId;
    if (address == defaultDeployer) {
      throw SmartAccountValidationException.invalidInput(
        'signer',
        'The shared default deployer $address cannot be a delegated signer: '
            'its secret derives from a public string, so anyone could '
            'authorize the account through it',
      );
    }
    if (address == walletContractId) {
      throw SmartAccountValidationException.invalidInput(
        'signer',
        'The smart account $walletContractId cannot be its own delegated '
            'signer',
      );
    }
    if (!StrKey.isValidStellarAccountId(address)) {
      throw SmartAccountInvalidAddress(
        'A delegated signer must be a Stellar account (G-address), got: '
        '$address. Delegating to a contract can let anyone authorize the '
        'account.',
      );
    }
  }
}
