// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../assets.dart';
import '../key_pair.dart';
import '../muxed_account.dart';
import '../muxed_contract.dart';
import '../network.dart';
import '../util.dart';
import '../xdr/xdr.dart';
import 'contract_address_guard.dart';
import 'contract_spec.dart';
import 'sac_spec.dart';
import 'soroban_auth.dart';
import 'soroban_client.dart';
import 'soroban_server.dart';

/// A typed client for a Stellar Asset Contract (SAC), the built-in token
/// contract of a classic asset, XLM included.
///
/// A SAC opens without a request: [SACClient.forAsset] and
/// [SACClient.forContractId] keep the spec embedded in the SDK, so the
/// functions are known before the contract is read. The asset forms derive
/// the contract id with [Asset.contractId] for the network, so each network
/// has its own id for the same asset. The native asset is `Asset.NATIVE`.
///
/// Reads ([balance], [decimals], [name], [symbol]) simulate the call and
/// return the result without signing or sending anything. The errors of a
/// balance read, and the contract codes they carry, are described in
/// [balance]. A keyed client's source account must exist for every call,
/// because building a transaction reads it and throws "Account: {id} not
/// found." when it is missing; a read-only client needs no account.
///
/// Writes ([transfer] and [transferAndSend]) take a [MethodOptions]. It
/// carries only the fee, the timeout, and the simulation, restore, and
/// upgraded-auth flags; a read-only client's writes follow
/// [AssembledTransactionOptions.readOnly].
/// With `simulate: false`, [transfer] returns an unsimulated transaction and
/// [transferAndSend] throws; call `simulate()` on the returned transaction
/// before inspecting or completing authorization entries. Authorization
/// entries of a contract address are completed as the contract's
/// `__check_auth` describes; see [AssembledTransaction.signAuthEntries].
///
/// Amounts are i128 base units of 7 decimals, as [BigInt]. [toBaseUnits]
/// converts a decimal string such as `"12.5"`.
///
/// The read-only mode, from [SACClient.readOnlyForAsset] and
/// [SACClient.readOnlyForContractId], uses the placeholder account
/// [READ_ONLY_SOURCE_ACCOUNT_ID], which no secret key produces.
///
/// Other functions of the contract are available through [sorobanClient],
/// with [SorobanClient.buildInvokeMethodTx].
///
/// See also:
/// - [SorobanClient] for the generic client and [SorobanClient.forSpecEntries]
/// - [AssembledTransaction.signAuthEntries] for authorization entries
/// - [SACSpec] for the embedded spec
class SACClient {
  /// The source account of a read-only client: the all-zero ed25519 public
  /// key, which no secret key produces. Reads simulate with it and need no
  /// account entry; a read-only client never signs with it.
  static const String READ_ONLY_SOURCE_ACCOUNT_ID =
      'GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF';

  /// The largest i128 amount, 2^127 - 1, in base units.
  static final BigInt _maxAmount = (BigInt.one << 127) - BigInt.one;

  /// The contract id of this client as a `C...` strkey.
  final String contractId;

  /// The client that wraps this contract, for the other functions of the
  /// contract, such as `sorobanClient.buildInvokeMethodTx`.
  final SorobanClient sorobanClient;

  /// Whether this client is read-only; see [SACClient.readOnlyForAsset].
  final bool _readOnly;

  /// This constructor is private. Use the factory methods instead.
  SACClient._(this.contractId, this.sorobanClient, this._readOnly);

  /// Returns the spec entries of the Stellar Asset Contract, decoded from the
  /// spec embedded in the SDK.
  ///
  /// Each call returns new objects. The decoding is strict and throws a
  /// [StateError] for a spec that does not decode or does not match its
  /// digest. Other Error types from decoding propagate unchanged; see
  /// [decodeSpec].
  static List<XdrSCSpecEntry> specEntries() {
    return decodeSpec(SACSpec.XDR_BASE64, SACSpec.SHA256);
  }

  /// Decodes the base64 XDR of a spec of `SCSpecEntry` values, checking it
  /// against [sha256Hex], the lowercase hex sha256 digest of the decoded
  /// bytes.
  ///
  /// The decoding is strict. The failures listed below throw a [StateError]:
  /// - [base64] is not valid base64: a StateError, whose trace starts at the
  ///   FormatException from `base64Decode`.
  /// - The digest of the decoded bytes is not [sha256Hex].
  /// - An entry throws an [Exception] or a [RangeError] while decoding; the
  ///   message gives its byte offset. Other [Error] types from decoding are
  ///   not wrapped and propagate unchanged.
  ///
  /// The base64 and decoding failures keep the original stack trace; the
  /// digest failure carries the trace of the check.
  @visibleForTesting
  static List<XdrSCSpecEntry> decodeSpec(String base64, String sha256Hex) {
    final Uint8List bytes;
    try {
      bytes = base64Decode(base64);
    } on FormatException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        StateError('The embedded SAC spec is not valid base64'),
        stackTrace,
      );
    }
    final actual = Util.bytesToHex(Util.hash(bytes));
    if (actual != sha256Hex) {
      Error.throwWithStackTrace(
        StateError(
          'The embedded SAC spec has sha256 $actual, expected $sha256Hex',
        ),
        StackTrace.current,
      );
    }

    final entries = <XdrSCSpecEntry>[];
    final stream = XdrDataInputStream(bytes);
    while (stream.offset! < bytes.length) {
      final start = stream.offset!;
      final XdrSCSpecEntry entry;
      try {
        entry = XdrSCSpecEntry.decode(stream);
      } on Exception catch (error, stackTrace) {
        _throwDecodeFailure(start, error, stackTrace);
      } on RangeError catch (error, stackTrace) {
        _throwDecodeFailure(start, error, stackTrace);
      }
      entries.add(entry);
    }
    return entries;
  }

  /// Throws the [StateError] of an entry that does not decode, keeping the
  /// trace of [error].
  static Never _throwDecodeFailure(
    int start,
    Object error,
    StackTrace stackTrace,
  ) {
    Error.throwWithStackTrace(
      StateError(
        'The embedded SAC spec does not decode at byte offset $start: $error',
      ),
      stackTrace,
    );
  }

  /// Opens the Stellar Asset Contract of [asset] on [network] with
  /// [sourceAccountKeyPair] as the sending account.
  ///
  /// The contract id is [Asset.contractId] for [network]. Sends no request.
  /// Throws an [UnsupportedError] for a liquidity pool share. [rpcUrl] and
  /// [server] select the RPC endpoint, as in [ClientOptions]; the keypair
  /// needs its private key for [transferAndSend].
  static SACClient forAsset({
    required Asset asset,
    required KeyPair sourceAccountKeyPair,
    required Network network,
    required String rpcUrl,
    SorobanServer? server,
  }) {
    return _open(
      contractId: asset.contractId(network),
      sourceAccountKeyPair: sourceAccountKeyPair,
      network: network,
      rpcUrl: rpcUrl,
      server: server,
      readOnly: false,
    );
  }

  /// Opens the Stellar Asset Contract with [contractId] on [network] with
  /// [sourceAccountKeyPair] as the sending account.
  ///
  /// [contractId] is a contract (C...) address, or the 64-character hex of a
  /// contract id. Sends no request. A muxed contract (W...) address, a
  /// secret seed, or another kind of address throws an [ArgumentError]
  /// before any request.
  static SACClient forContractId({
    required String contractId,
    required KeyPair sourceAccountKeyPair,
    required Network network,
    required String rpcUrl,
    SorobanServer? server,
  }) {
    return _open(
      contractId: contractId,
      sourceAccountKeyPair: sourceAccountKeyPair,
      network: network,
      rpcUrl: rpcUrl,
      server: server,
      readOnly: false,
    );
  }

  /// Opens the Stellar Asset Contract of [asset] on [network] in read-only
  /// mode, without a keypair.
  ///
  /// The client uses [READ_ONLY_SOURCE_ACCOUNT_ID] as its source. Its reads
  /// return the same values as a keyed client's, and need no account entry.
  /// Its writes follow [AssembledTransactionOptions.readOnly]. Sends no
  /// request.
  static SACClient readOnlyForAsset({
    required Asset asset,
    required Network network,
    required String rpcUrl,
    SorobanServer? server,
  }) {
    return _open(
      contractId: asset.contractId(network),
      network: network,
      rpcUrl: rpcUrl,
      server: server,
      readOnly: true,
    );
  }

  /// Opens the Stellar Asset Contract with [contractId] on [network] in
  /// read-only mode, without a keypair.
  ///
  /// [contractId] takes the forms of [forContractId]. The read-only behavior
  /// is that of [readOnlyForAsset]. Sends no request.
  static SACClient readOnlyForContractId({
    required String contractId,
    required Network network,
    required String rpcUrl,
    SorobanServer? server,
  }) {
    return _open(
      contractId: contractId,
      network: network,
      rpcUrl: rpcUrl,
      server: server,
      readOnly: true,
    );
  }

  /// The one factory behind the public factories. A read-only client takes
  /// the placeholder account in place of [sourceAccountKeyPair].
  static SACClient _open({
    required String contractId,
    KeyPair? sourceAccountKeyPair,
    required Network network,
    required String rpcUrl,
    SorobanServer? server,
    required bool readOnly,
  }) {
    final id = _contractStrKey(contractId);
    final keyPair = readOnly
        ? KeyPair.fromAccountId(READ_ONLY_SOURCE_ACCOUNT_ID)
        : sourceAccountKeyPair!;
    final client = SorobanClient.forSpecEntries(
      specEntries: specEntries(),
      options: ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: id,
        network: network,
        rpcUrl: rpcUrl,
        server: server,
      ),
      readOnly: readOnly,
    );
    return SACClient._(id, client, readOnly);
  }

  /// Returns [contractId] as a `C...` strkey. [checkContractAddress] validates
  /// the value; a 64-character hex id is then encoded as its strkey.
  static String _contractStrKey(String contractId) {
    checkContractAddress(contractId, 'The contract to invoke');
    if (StrKey.isValidContractId(contractId)) {
      return contractId;
    }
    return StrKey.encodeContractIdHex(contractId);
  }

  /// Converts a decimal [amount] to base units of 7 decimals.
  ///
  /// [amount] is decimal digits with at most 7 fractional digits, such as
  /// `"12.5"`, which gives `125000000`. Surrounding whitespace, a sign, an
  /// exponent, a missing digit on either side of the point, and non-ASCII
  /// digits are rejected with an [ArgumentError]. A secret seed is rejected
  /// by kind, without its value in the message. The result must fit an i128,
  /// at most 170141183460469231731687303715884105727 base units, which is
  /// 17014118346046923173168730371588.4105727 in decimal.
  ///
  /// Example:
  /// ```dart
  /// BigInt amount = SACClient.toBaseUnits('12.5'); // 125000000
  /// ```
  static BigInt toBaseUnits(String amount) {
    final kind = secretSeedLikeKind(amount);
    if (kind != null) {
      throw ArgumentError(
        'Invalid amount: got $kind instead of a decimal amount',
      );
    }
    if (!RegExp(r'^[0-9]+(\.[0-9]{1,7})?$').hasMatch(amount)) {
      throw ArgumentError(
        'Invalid amount ${XdrJsonHelper.preview(redactSecretSeeds(amount))}: '
        'expected decimal digits with at most 7 fractional digits, such as '
        '12.5',
      );
    }
    final point = amount.indexOf('.');
    final whole = point < 0 ? amount : amount.substring(0, point);
    final fraction = point < 0 ? '' : amount.substring(point + 1);
    final value = BigInt.parse(whole + fraction.padRight(7, '0'), radix: 10);
    if (value > _maxAmount) {
      throw ArgumentError(
        'Amount $amount exceeds the largest i128 amount, '
        '17014118346046923173168730371588.4105727',
      );
    }
    return value;
  }

  /// Returns the balance of [holder] in base units.
  ///
  /// [holder] is an account (G...) or contract (C...) address. The balance of
  /// an account that does not exist, or of an issued asset held by an account
  /// without a trustline, throws a `SorobanSimulationException`. When its
  /// `reportedContractError` is set, the code is 6 for a missing account and 13
  /// for a missing trustline; the simulation may report no code, in which case
  /// it is null. An existing balance, zero included, is returned.
  /// A contract holder with no balance reads 0. A muxed holder throws an
  /// [ArgumentError] before any request, naming its base address for the
  /// query. A claimable balance (B...) or liquidity pool (L...) holder throws
  /// a [ContractSpecException] before any request, because the host produces
  /// those addresses and a contract cannot take them as input.
  Future<BigInt> balance(Address holder) async {
    final holderXdr = holder.toXdr();
    if (holderXdr.discriminant ==
        XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT) {
      final muxed = holderXdr.toStrKey();
      final base = MuxedAccount.fromAccountId(muxed)!.ed25519AccountId;
      throw ArgumentError(
        'The balance holder must be an account (G...) or contract (C...) '
        'address, got a muxed account (M...) address: $muxed; query its base '
        'account $base',
      );
    }
    if (holderXdr.discriminant ==
        XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_CONTRACT) {
      final muxed = holderXdr.toStrKey();
      final base = MuxedContract.fromMuxedContractId(muxed).contractId;
      throw ArgumentError(
        'The balance holder must be an account (G...) or contract (C...) '
        'address, got a muxed contract (W...) address: $muxed; query its base '
        'contract $base',
      );
    }
    final value = await _read('balance', {'id': holder});
    _expectArm(value, 'balance', XdrSCValType.SCV_I128);
    return value.toBigInt()!;
  }

  /// Returns the number of decimals of this asset, which is 7 for every
  /// Stellar Asset Contract.
  Future<int> decimals() async {
    final value = await _read('decimals', {});
    _expectArm(value, 'decimals', XdrSCValType.SCV_U32);
    return value.u32!.uint32;
  }

  /// Returns the name of this asset: `native` for XLM, otherwise `CODE:ISSUER`.
  Future<String> name() async {
    final value = await _read('name', {});
    _expectArm(value, 'name', XdrSCValType.SCV_STRING);
    return value.str!;
  }

  /// Returns the symbol of this asset: `native` for XLM, otherwise its code.
  Future<String> symbol() async {
    final value = await _read('symbol', {});
    _expectArm(value, 'symbol', XdrSCValType.SCV_STRING);
    return value.str!;
  }

  /// Builds a transfer of [amount] base units from [from] to [to].
  ///
  /// [from] is a G or C address, and [to] a G, M, C, or W address. Other
  /// kinds, such as a claimable balance or a liquidity pool, throw a
  /// [ContractSpecException] before any request. [amount] must be from 0 to
  /// 2^127 - 1; a value outside throws an [ArgumentError] before any request.
  ///
  /// The transaction is simulated unless [methodOptions] sets
  /// `simulate: false`. Sign and send it with `signAndSend()` after the
  /// simulation, from a keyed client with [from] as the source. A read-only
  /// client's transfer with `simulate: false` returns an unsimulated
  /// transaction; its signing and sending follow
  /// [AssembledTransactionOptions.readOnly]. A G [from] other than the source
  /// appears in `needsNonInvokerSigningBy()`; its holder completes it with
  /// `signAuthEntries(signerKeyPair: ...)` before `signAndSend()`. A C [from]
  /// authorizes through its own `__check_auth`, which the caller completes as
  /// the contract requires.
  Future<AssembledTransaction> transfer({
    required Address from,
    required Address to,
    required BigInt amount,
    MethodOptions? methodOptions,
  }) async {
    if (amount < BigInt.zero || amount > _maxAmount) {
      throw ArgumentError(
        'The transfer amount must be from 0 to $_maxAmount base units, got '
        '$amount',
      );
    }
    return sorobanClient.buildInvokeMethodTx(
      name: 'transfer',
      args: sorobanClient.funcArgsToXdrSCValues('transfer', {
        'from': from,
        'to': to,
        'amount': amount,
      }),
      methodOptions: methodOptions,
    );
  }

  /// Transfers [amount] base units from the source account of this client to
  /// [to], signs the transaction, sends it, and waits for its result.
  ///
  /// A read-only client throws an [Exception], before any request, saying that
  /// transferAndSend needs the sending account's keypair. Otherwise it builds
  /// the transfer with the source account as [from], then calls
  /// `signAndSend()`.
  /// With `simulate: false` in [methodOptions] the transfer is unsimulated, so
  /// the keyed client throws "Transaction has not yet been simulated", as
  /// `sign()` does, and nothing is sent.
  /// A status other than `SUCCESS` throws an [Exception] with the result XDR.
  /// The errors of sending and polling are those of
  /// `AssembledTransaction.send`; a transaction still pending at the deadline
  /// throws, and the caller polls its hash again.
  Future<GetTransactionResponse> transferAndSend({
    required Address to,
    required BigInt amount,
    MethodOptions? methodOptions,
  }) async {
    if (_readOnly) {
      throw Exception(
        "transferAndSend needs the sending account's keypair, and this "
        "SACClient is read-only; open the client with SACClient.forAsset() or "
        "SACClient.forContractId()",
      );
    }
    final sourceAccountId = sorobanClient
        .getOptions()
        .sourceAccountKeyPair
        .accountId;
    final tx = await transfer(
      from: Address.forAccountId(sourceAccountId),
      to: to,
      amount: amount,
      methodOptions: methodOptions,
    );
    final response = await tx.signAndSend();
    if (response.status != GetTransactionResponse.STATUS_SUCCESS) {
      throw Exception(
        "The transfer did not succeed: status ${response.status}, transaction "
        "result xdr: ${response.resultXdr}",
      );
    }
    return response;
  }

  /// Simulates a read of [function] with [args] and returns the value the
  /// contract returns.
  ///
  /// A read that needs archived ledger entries throws, because a read does
  /// not restore them.
  Future<XdrSCVal> _read(String function, Map<String, dynamic> args) async {
    final tx = await sorobanClient.buildInvokeMethodTx(
      name: function,
      args: sorobanClient.funcArgsToXdrSCValues(function, args),
      methodOptions: MethodOptions(restore: false),
    );
    if (tx.simulationResponse!.restorePreamble != null) {
      throw Exception(
        "The Stellar Asset Contract $contractId cannot run $function: ledger "
        "entries it needs are archived; restore them from a client opened "
        "with a funded account's keypair",
      );
    }
    return tx.getSimulationData().returnedValue;
  }

  /// Throws an [Exception] unless [value] has the arm [expected]; the message
  /// names the arm that was returned.
  void _expectArm(XdrSCVal value, String function, XdrSCValType expected) {
    if (value.discriminant != expected) {
      throw Exception(
        "The Stellar Asset Contract $contractId returned "
        "${value.discriminant.enumName()} from $function, expected "
        "${expected.enumName()}",
      );
    }
  }
}
