// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import '../key_pair.dart';
import '../network.dart';
import '../util.dart';
import '../xdr/xdr_contract.dart';
import '../xdr/xdr_transaction.dart';
import '../xdr/xdr_type.dart';
import '../xdr/xdr_data_io.dart';

/// Represents an address in Soroban smart contracts.
///
/// An Address identifies different types of entities in the Stellar network:
/// - Accounts: Regular Stellar accounts (G... addresses)
/// - Contracts: Deployed smart contracts (C... addresses)
/// - Muxed Accounts: Multiplexed accounts (M... addresses, protocol >= 23)
/// - Claimable Balances: Claimable balance entries (protocol >= 23)
/// - Liquidity Pools: Liquidity pool entries (protocol >= 23)
///
/// Addresses are used as arguments to contract functions and can represent
/// different authorization contexts in Soroban transactions.
///
/// Factory methods:
/// - [Address.forAccountId]: Create from Stellar account ID (G...)
/// - [Address.forContractId]: Create from contract ID (C...)
/// - [Address.forMuxedAccountId]: Create from muxed account (M...)
/// - [Address.forClaimableBalanceId]: Create from claimable balance ID
/// - [Address.forLiquidityPoolId]: Create from liquidity pool ID
/// - [Address.fromXdr]: Create from XdrSCAddress
/// - [Address.fromXdrSCVal]: Create from XdrSCVal containing an address
///
/// Example:
/// ```dart
/// // Create address for an account
/// final accountAddr = Address.forAccountId('GABC...');
/// final accountScVal = accountAddr.toXdrSCVal();
///
/// // Create address for a contract
/// final contractAddr = Address.forContractId('CABC...');
/// final contractScVal = contractAddr.toXdrSCVal();
///
/// // Use as contract function argument
/// final result = await client.invokeMethod(
///   name: 'transfer',
///   args: [
///     Address.forAccountId(fromAccount).toXdrSCVal(),
///     Address.forAccountId(toAccount).toXdrSCVal(),
///     XdrSCVal.forI128Parts(0, amount),
///   ],
/// );
/// ```
///
/// Example - Check address type:
/// ```dart
/// if (address.type == Address.TYPE_ACCOUNT) {
///   print('Account: ${address.accountId}');
/// } else if (address.type == Address.TYPE_CONTRACT) {
///   print('Contract: ${address.contractId}');
/// }
/// ```
///
/// See also:
/// - [XdrSCAddress] for XDR representation
/// - [SorobanAuthorizationEntry] for authorization contexts
class Address {
  /// Account address type (G... addresses). Supported in all protocol versions.
  static const int TYPE_ACCOUNT = 0;

  /// Contract address type (C... addresses). Supported in all protocol versions.
  static const int TYPE_CONTRACT = 1;

  /// Muxed account address type (M... addresses). Requires protocol version 23 or higher.
  static const int TYPE_MUXED_ACCOUNT = 2;

  /// Claimable balance address type. Requires protocol version 23 or higher.
  static const int TYPE_CLAIMABLE_BALANCE = 3;

  /// Liquidity pool address type. Requires protocol version 23 or higher.
  static const int TYPE_LIQUIDITY_POOL = 4;

  int _type;

  /// The type of the Address (TYPE_ACCOUNT or TYPE_CONTRACT).
  get type => _type;

  /// The id of the account if type is TYPE_ACCOUNT otherwise null.
  String? accountId;

  /// The id of the contract if type is TYPE_CONTRACT otherwise null.
  String? contractId;

  /// The id of the account if type is TYPE_MUXED_ACCOUNT otherwise null.
  String? muxedAccountId;

  /// The id of the claimable balance if type is TYPE_CLAIMABLE_BALANCE otherwise null.
  String? claimableBalanceId;

  /// The id of the liquidity pool if type is TYPE_LIQUIDITY_POOL otherwise null.
  String? liquidityPoolId;

  /// Constructs an [Address] for the given [type] which can
  /// be one of: [Address.TYPE_ACCOUNT], [Address.TYPE_CONTRACT],
  /// [Address.TYPE_CLAIMABLE_BALANCE], [Address.TYPE_LIQUIDITY_POOL].
  ///
  /// If [Address.TYPE_ACCOUNT] one must provide [accountId].
  /// If [Address.TYPE_CONTRACT] one must provide [contractId].
  /// If [Address.TYPE_MUXED_ACCOUNT] one must provide [muxedAccountId].
  /// If [Address.TYPE_CLAIMABLE_BALANCE] one must provide [claimableBalanceId].
  /// If [Address.TYPE_LIQUIDITY_POOL] one must provide [liquidityPoolId].
  Address(this._type, {this.accountId, this.contractId, this.muxedAccountId,
    this.claimableBalanceId, this.liquidityPoolId}) {
    if (this._type != TYPE_ACCOUNT && this._type != TYPE_CONTRACT &&
        this._type != TYPE_MUXED_ACCOUNT  && this._type != TYPE_CLAIMABLE_BALANCE
        && this._type != TYPE_LIQUIDITY_POOL) {
      throw new Exception("unknown type");
    }

    if (this._type == TYPE_ACCOUNT && this.accountId == null) {
      throw new Exception("invalid arguments");
    }

    if (this._type == TYPE_CONTRACT && this.contractId == null) {
      throw new Exception("invalid arguments");
    }

    if (this._type == TYPE_MUXED_ACCOUNT && this.muxedAccountId == null) {
      throw new Exception("invalid arguments");
    }

    if (this._type == TYPE_CLAIMABLE_BALANCE && this.claimableBalanceId == null) {
      throw new Exception("invalid arguments");
    }

    if (this._type == TYPE_LIQUIDITY_POOL && this.liquidityPoolId == null) {
      throw new Exception("invalid arguments");
    }
  }

  /// Constructs an [Address] of type [Address.TYPE_ACCOUNT] for the given [accountId] ("G...").
  static Address forAccountId(String accountId) {
    return Address(TYPE_ACCOUNT, accountId: accountId);
  }

  /// Constructs an [Address] of type [Address.TYPE_CONTRACT] for the given [contractId].
  static Address forContractId(String contractId) {
    return Address(TYPE_CONTRACT, contractId: contractId);
  }

  /// Constructs an [Address] of type [Address.TYPE_MUXED_ACCOUNT] for the given [muxedAccountId] ("M...").
  static Address forMuxedAccountId(String muxedAccountId) {
    return Address(TYPE_MUXED_ACCOUNT, muxedAccountId: muxedAccountId);
  }

  /// Constructs an [Address] of type [Address.TYPE_CLAIMABLE_BALANCE] for the given [claimableBalanceId].
  static Address forClaimableBalanceId(String claimableBalanceId) {
    return Address(TYPE_CLAIMABLE_BALANCE, claimableBalanceId: claimableBalanceId);
  }

  /// Constructs an [Address] of type [Address.TYPE_LIQUIDITY_POOL] for the given [liquidityPoolId].
  static Address forLiquidityPoolId(String liquidityPoolId) {
    return Address(TYPE_LIQUIDITY_POOL, liquidityPoolId: liquidityPoolId);
  }

  /// Constructs an [Address] from the given [xdr].
  static Address fromXdr(XdrSCAddress xdr) {
    if (xdr.discriminant == XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT) {
      KeyPair kp = KeyPair.fromXdrPublicKey(xdr.accountId!.accountID);
      return Address(TYPE_ACCOUNT, accountId: kp.accountId);
    } else if (xdr.discriminant == XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT) {
      return Address(TYPE_CONTRACT,
          contractId: Util.bytesToHex(xdr.contractId!.hash));
    } else if (xdr.discriminant == XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT) {
      return Address(TYPE_MUXED_ACCOUNT, muxedAccountId: xdr.muxedAccount!.accountId);
    } else if (xdr.discriminant == XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE) {
      return Address(TYPE_CLAIMABLE_BALANCE,
          claimableBalanceId: xdr.claimableBalanceId!.claimableBalanceIdString);
    } else if (xdr.discriminant == XdrSCAddressType.SC_ADDRESS_TYPE_LIQUIDITY_POOL) {
      return Address(TYPE_LIQUIDITY_POOL,
          liquidityPoolId: Util.bytesToHex(xdr.liquidityPoolId!.hash));
    } else {
      throw Exception("unknown address type " + xdr.discriminant.toString());
    }
  }

  /// Returns a [XdrSCAddress] object created from this [Address] object.
  XdrSCAddress toXdr() {
    if (_type == TYPE_ACCOUNT) {
      if (accountId == null) {
        throw Exception("invalid address, has no account id");
      }
      return XdrSCAddress.forAccountId(accountId!);
    } else if (_type == TYPE_CONTRACT) {
      if (contractId == null) {
        throw Exception("invalid address, has no contract id");
      }
      return XdrSCAddress.forContractId(contractId!);
    } else if (_type == TYPE_MUXED_ACCOUNT) {
      if (muxedAccountId == null) {
        throw Exception("invalid address, has no muxed account id");
      }
      return XdrSCAddress.forAccountId(muxedAccountId!);
    } else if (_type == TYPE_CLAIMABLE_BALANCE) {
      if (claimableBalanceId == null) {
        throw Exception("invalid address, has no claimable balance id");
      }
      return XdrSCAddress.forClaimableBalanceId(claimableBalanceId!);
    } else if (_type == TYPE_LIQUIDITY_POOL) {
      if (liquidityPoolId == null) {
        throw Exception("invalid address, has no liquidity pool id");
      }
      return XdrSCAddress.forLiquidityPoolId(liquidityPoolId!);
    } else {
      throw Exception("unknown address type " + _type.toString());
    }
  }

  /// Returns a [XdrSCVal] containing an [XdrSCObject] for this [Address].
  XdrSCVal toXdrSCVal() {
    return XdrSCVal.forAddress(toXdr());
  }

  static Address fromXdrSCVal(XdrSCVal val) {
    if (val.discriminant == XdrSCValType.SCV_ADDRESS && val.address != null) {
      return fromXdr(val.address!);
    }
    throw ArgumentError('Given XdrSCVal is not of type address.');
  }

}

/// Address-based authorization credentials for Soroban contract invocations.
///
/// Contains signature and metadata required for multi-party authorization.
/// Used when an account other than the transaction source needs to authorize
/// a specific contract invocation.
///
/// Fields:
/// - [address]: The address authorizing the invocation
/// - [nonce]: Unique value to prevent replay attacks
/// - [signatureExpirationLedger]: Ledger number when signature expires
/// - [signature]: Cryptographic signature proving authorization
class SorobanAddressCredentials {
  Address address;
  int nonce;
  int signatureExpirationLedger;
  XdrSCVal signature;

  SorobanAddressCredentials(
      this.address, this.nonce, this.signatureExpirationLedger, this.signature);

  static SorobanAddressCredentials fromXdr(XdrSorobanAddressCredentials xdr) {
    return SorobanAddressCredentials(Address.fromXdr(xdr.address),
        xdr.nonce.int64, xdr.signatureExpirationLedger.uint32, xdr.signature);
  }

  XdrSorobanAddressCredentials toXdr() {
    return new XdrSorobanAddressCredentials(address.toXdr(), XdrInt64(nonce),
        XdrUint32(signatureExpirationLedger), signature);
  }
}

/// Authorization credentials for Soroban contract invocations.
///
/// Soroban supports two authorization modes:
///
/// 1. Source Account Authorization (implicit):
///    - Used when the transaction source account authorizes the invocation
///    - No explicit signature required in the auth entry
///    - Created via [SorobanCredentials.forSourceAccount]
///    - The transaction signature itself provides authorization
///
/// 2. Address Credentials Authorization (explicit):
///    - Used for multi-party transactions where accounts other than the source
///      must authorize specific invocations
///    - Requires explicit signature in [addressCredentials]
///    - Created via [SorobanCredentials.forAddress] or [SorobanCredentials.forAddressCredentials]
///    - Common in token swaps, escrow releases, and multi-sig scenarios
///
/// Example - Source account authorization:
/// ```dart
/// // Transaction source account implicitly authorizes
/// final credentials = SorobanCredentials.forSourceAccount();
/// ```
///
/// Example - Multi-party authorization:
/// ```dart
/// // Another party must sign this auth entry
/// final authEntry = simulationResponse.auth![0];
/// authEntry.sign(otherPartyKeyPair, network);
/// ```
///
/// See also:
/// - [SorobanAuthorizationEntry] for complete authorization entry structure
/// - [AssembledTransaction.signAuthEntries] for signing workflows
class SorobanCredentials {
  SorobanAddressCredentials? addressCredentials;

  SorobanCredentials({SorobanAddressCredentials? addressCredentials}) {
    if (addressCredentials != null) {
      this.addressCredentials = addressCredentials;
    }
  }

  /// Creates credentials for source account authorization.
  ///
  /// Use when the transaction source account authorizes the invocation.
  /// No explicit signature is required; transaction signature provides authorization.
  static SorobanCredentials forSourceAccount() {
    return SorobanCredentials();
  }

  /// Creates credentials for address-based authorization.
  ///
  /// Use when an account other than the source must authorize the invocation.
  /// The specified address must sign the authorization entry.
  static SorobanCredentials forAddress(Address address, int nonce,
      int signatureExpirationLedger, XdrSCVal signature) {
    SorobanAddressCredentials addressCredentials = SorobanAddressCredentials(
        address, nonce, signatureExpirationLedger, signature);
    return SorobanCredentials(addressCredentials: addressCredentials);
  }

  static SorobanCredentials forAddressCredentials(
      SorobanAddressCredentials addressCredentials) {
    return SorobanCredentials(addressCredentials: addressCredentials);
  }

  static SorobanCredentials fromXdr(XdrSorobanCredentials xdr) {
    if (xdr.type == XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS &&
        xdr.address != null) {
      return SorobanCredentials.forAddressCredentials(
          SorobanAddressCredentials.fromXdr(xdr.address!));
    }
    return SorobanCredentials();
  }

  XdrSorobanCredentials toXdr() {
    if (addressCredentials != null) {
      XdrSorobanCredentials cred = XdrSorobanCredentials(
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS);
      cred.address = addressCredentials!.toXdr();
      return cred;
    }
    return XdrSorobanCredentials(
        XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT);
  }
}

class SorobanAuthorizedFunction {
  XdrInvokeContractArgs? contractFn;
  XdrCreateContractArgs? createContractHostFn;
  XdrCreateContractArgsV2? createContractV2HostFn;

  SorobanAuthorizedFunction(
      {XdrInvokeContractArgs? contractFn,
      XdrCreateContractArgs? createContractHostFn,
        XdrCreateContractArgsV2? createContractV2HostFn}) {
    if (contractFn == null && createContractHostFn == null && createContractV2HostFn == null) {
      throw ArgumentError("invalid arguments");
    }

    this.contractFn = contractFn;
    this.createContractHostFn = createContractHostFn;
    this.createContractV2HostFn = createContractV2HostFn;
  }

  static SorobanAuthorizedFunction forContractFunction(
      Address contractAddress, String functionName, List<XdrSCVal> args) {
    XdrInvokeContractArgs cfn =
        XdrInvokeContractArgs(contractAddress.toXdr(), functionName, args);
    return SorobanAuthorizedFunction(contractFn: cfn);
  }

  static SorobanAuthorizedFunction forCreateContractHostFunction(
      XdrCreateContractArgs createContractHostFn) {
    return SorobanAuthorizedFunction(
        createContractHostFn: createContractHostFn);
  }

  static SorobanAuthorizedFunction forCreateContractV2HostFunction(
      XdrCreateContractArgsV2 createContractV2HostFn) {
    return SorobanAuthorizedFunction(
        createContractV2HostFn: createContractV2HostFn);
  }

  static SorobanAuthorizedFunction fromXdr(XdrSorobanAuthorizedFunction xdr) {
    if (xdr.type ==
            XdrSorobanAuthorizedFunctionType
                .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN &&
        xdr.contractFn != null) {
      return SorobanAuthorizedFunction(
          contractFn:xdr.contractFn!);
    } else if (xdr.type ==
        XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN &&
        xdr.createContractHostFn != null) {
      return SorobanAuthorizedFunction(
          createContractHostFn: xdr.createContractHostFn);
    } else {
      return SorobanAuthorizedFunction(
          createContractV2HostFn: xdr.createContractV2HostFn);
    }
  }

  XdrSorobanAuthorizedFunction toXdr() {
    if (contractFn != null) {
      XdrSorobanAuthorizedFunction cfn = XdrSorobanAuthorizedFunction(
          XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN);
      cfn.contractFn = contractFn!;
      return cfn;
    } else if (createContractHostFn != null) {
      XdrSorobanAuthorizedFunction cfn = XdrSorobanAuthorizedFunction(
          XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN);
      cfn.createContractHostFn = createContractHostFn!;
      return cfn;
    }
    XdrSorobanAuthorizedFunction cfn = XdrSorobanAuthorizedFunction(
        XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN);
    cfn.createContractV2HostFn = createContractV2HostFn!;
    return cfn;
  }
}

class SorobanAuthorizedInvocation {
  SorobanAuthorizedFunction function;
  List<SorobanAuthorizedInvocation> subInvocations =
      List<SorobanAuthorizedInvocation>.empty(growable: true);

  SorobanAuthorizedInvocation(this.function,
      {List<SorobanAuthorizedInvocation>? subInvocations}) {
    if (subInvocations != null) {
      this.subInvocations = subInvocations;
    }
  }

  static SorobanAuthorizedInvocation fromXdr(
      XdrSorobanAuthorizedInvocation xdr) {
    List<SorobanAuthorizedInvocation> subInvocations =
        List<SorobanAuthorizedInvocation>.empty(growable: true);
    for (XdrSorobanAuthorizedInvocation subXdr in xdr.subInvocations) {
      subInvocations.add(SorobanAuthorizedInvocation.fromXdr(subXdr));
    }
    return SorobanAuthorizedInvocation(
        SorobanAuthorizedFunction.fromXdr(xdr.function),
        subInvocations: subInvocations);
  }

  XdrSorobanAuthorizedInvocation toXdr() {
    List<XdrSorobanAuthorizedInvocation> xdrSubInvocations =
        List<XdrSorobanAuthorizedInvocation>.empty(growable: true);
    for (SorobanAuthorizedInvocation sub in this.subInvocations) {
      xdrSubInvocations.add(sub.toXdr());
    }
    return XdrSorobanAuthorizedInvocation(
        this.function.toXdr(), xdrSubInvocations);
  }
}

/// Authorization entry for Soroban contract invocations.
///
/// SorobanAuthorizationEntry represents authorization for a contract function call
/// in a multi-party transaction. Each entry specifies:
/// - Which account/contract is authorizing the invocation
/// - The function being authorized (and any sub-invocations)
/// - The signature or proof of authorization
///
/// Authorization entries are used in scenarios where multiple parties must approve
/// different parts of a transaction (e.g., token swaps, escrow releases).
///
/// Example:
/// ```dart
/// // Transaction simulation provides auth entries
/// final simulation = await server.simulateTransaction(request);
/// final authEntries = simulation.getSorobanAuth();
///
/// // Sign auth entries for each required signer
/// for (var entry in authEntries) {
///   if (entry.credentials.addressCredentials != null) {
///     final signerAddress = entry.credentials.addressCredentials!.address;
///     // Get appropriate keypair and sign
///     entry.sign(signerKeyPair, network);
///   }
/// }
///
/// // Update transaction with signed auth entries
/// tx.setSorobanAuth(authEntries);
/// ```
///
/// See also:
/// - [SorobanCredentials] for authorization methods
/// - [SorobanAuthorizedInvocation] for function call details
/// - [AssembledTransaction.signAuthEntries] for high-level signing
class SorobanAuthorizationEntry {
  SorobanCredentials credentials;
  SorobanAuthorizedInvocation rootInvocation;
  SorobanAuthorizationEntry(this.credentials, this.rootInvocation);

  static SorobanAuthorizationEntry fromXdr(XdrSorobanAuthorizationEntry xdr) {
    return SorobanAuthorizationEntry(
        SorobanCredentials.fromXdr(xdr.credentials),
        SorobanAuthorizedInvocation.fromXdr(xdr.rootInvocation));
  }

  XdrSorobanAuthorizationEntry toXdr() {
    return XdrSorobanAuthorizationEntry(
        this.credentials.toXdr(), this.rootInvocation.toXdr());
  }

  static SorobanAuthorizationEntry fromBase64EncodedXdr(String xdr) {
    Uint8List bytes = base64Decode(xdr);
    return SorobanAuthorizationEntry.fromXdr(
        XdrSorobanAuthorizationEntry.decode(XdrDataInputStream(bytes)));
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrSorobanAuthorizationEntry.encode(xdrOutputStream, this.toXdr());
    return base64Encode(xdrOutputStream.bytes);
  }

  /// Signs the authorization entry.
  /// The signature will be set to the soroban credentials
  void sign(KeyPair signer, Network network) {
    XdrSorobanCredentials xdrCredentials = credentials.toXdr();
    if (credentials.addressCredentials == null ||
        xdrCredentials.type !=
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS ||
        xdrCredentials.address == null) {
      throw Exception("no soroban address credentials found");
    }

    XdrHashIDPreimageSorobanAuthorization authPreimageXdr =
        XdrHashIDPreimageSorobanAuthorization(
            XdrHash(network.networkId!),
            xdrCredentials.address!.nonce,
            xdrCredentials.address!.signatureExpirationLedger,
            rootInvocation.toXdr());
    XdrHashIDPreimage rootInvocationPreimage =
        XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION);
    rootInvocationPreimage.sorobanAuthorization = authPreimageXdr;
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrHashIDPreimage.encode(xdrOutputStream, rootInvocationPreimage);
    Uint8List payload = Util.hash(Uint8List.fromList(xdrOutputStream.bytes));
    Uint8List signatureBytes = signer.sign(payload);
    AccountEd25519Signature signature =
        AccountEd25519Signature(signer.xdrPublicKey, signatureBytes);
    List<XdrSCVal> signatures = List<XdrSCVal>.empty(growable: true);
    if (credentials.addressCredentials!.signature.vec != null) {
      signatures.addAll(credentials.addressCredentials!.signature.vec!);
    }
    signatures.add(signature.toXdrSCVal());
    credentials.addressCredentials!.signature = XdrSCVal.forVec(signatures);
  }
}

/// Represents a signature used by [SorobanAuthorizationEntry].
class AccountEd25519Signature {
  XdrPublicKey publicKey;
  Uint8List signatureBytes;

  AccountEd25519Signature(this.publicKey, this.signatureBytes);

  XdrSCVal toXdrSCVal() {
    XdrSCVal pkVal = XdrSCVal.forBytes(publicKey.getEd25519()!.uint256);
    XdrSCVal sigVal = XdrSCVal.forBytes(signatureBytes);
    XdrSCMapEntry pkEntry =
        XdrSCMapEntry(XdrSCVal.forSymbol("public_key"), pkVal);
    XdrSCMapEntry sigEntry =
        XdrSCMapEntry(XdrSCVal.forSymbol("signature"), sigVal);
    return XdrSCVal.forMap([pkEntry, sigEntry]);
  }
}
