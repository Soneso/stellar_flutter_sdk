// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import '../key_pair.dart';
import '../network.dart';
import '../util.dart';
import '../xdr/xdr.dart';

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
///     XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(amount)),
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
  ///
  /// [Address.fromXdr] reports it in the spelling Horizon serves: the hex of
  /// the XDR encoding, the four byte type discriminant ahead of the hash.
  /// Every spelling [XdrClaimableBalanceID.forId] accepts may be given here.
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
          claimableBalanceId: xdr.claimableBalanceId!.paddedBalanceIdHex);
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

  /// Returns a [XdrSCVal] containing an [XdrSCAddress] for this [Address].
  XdrSCVal toXdrSCVal() {
    return XdrSCVal.forAddress(toXdr());
  }

  /// Creates an address from an XDR SCVal representation.
  static Address fromXdrSCVal(XdrSCVal val) {
    if (val.discriminant == XdrSCValType.SCV_ADDRESS && val.address != null) {
      return fromXdr(val.address!);
    }
    throw ArgumentError('Given XdrSCVal is not of type address.');
  }

  /// Derives the contract id a deployment by the given [deployer] with the
  /// given [salt] creates on the given [network].
  ///
  /// The id depends only on the deployer address, the salt and the network;
  /// the executable the contract is created with (wasm hash, CAP-85 external
  /// reference or Stellar asset) does not enter the derivation. Use it to know
  /// a contract's address before deploying, for example when the address is
  /// needed in constructor arguments of another contract.
  ///
  /// Returns the derived contract id ("C...").
  ///
  /// Throws [ArgumentError] if [salt] is not exactly 32 bytes.
  static String deriveContractId(
      {required Address deployer,
      required Uint8List salt,
      required Network network}) {
    if (salt.length != 32) {
      throw ArgumentError(
          "salt must be exactly 32 bytes, got ${salt.length}");
    }
    final networkId = network.networkId;
    if (networkId == null) {
      throw ArgumentError("network has no id");
    }

    final contractIdPreimage = XdrContractIDPreimage(
        XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
    contractIdPreimage.fromAddress =
        XdrContractIDPreimageFromAddress(deployer.toXdr(), XdrUint256(salt));

    final preimage = XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID);
    preimage.contractID =
        XdrHashIDPreimageContractID(XdrHash(networkId), contractIdPreimage);

    final stream = XdrDataOutputStream();
    XdrHashIDPreimage.encode(stream, preimage);
    final contractIdBytes = Util.hash(Uint8List.fromList(stream.bytes));
    return StrKey.encodeContractId(contractIdBytes);
  }

}

/// Address-based authorization credentials for Soroban contract invocations.
///
/// Contains signature and metadata required for multi-party authorization.
/// Used when an account other than the transaction source needs to authorize
/// a specific contract invocation.
///
/// Fields:
/// - [address] The address authorizing the invocation
/// - [nonce] Unique value to prevent replay attacks
/// - [signatureExpirationLedger] Ledger number when signature expires
/// - [signature] Cryptographic signature proving authorization
class SorobanAddressCredentials {
  Address address;

  /// Nonce value preventing replay attacks.
  BigInt nonce;

  /// Ledger number when the signature expires.
  int signatureExpirationLedger;

  /// Cryptographic signature proving authorization.
  XdrSCVal signature;

  /// Creates SorobanAddressCredentials with all authorization components.
  ///
  /// This constructor initializes the credentials required for multi-party authorization
  /// in Soroban transactions. Each field is essential for preventing replay attacks and
  /// ensuring signatures are valid for the intended context.
  ///
  /// Parameters:
  /// - [address] The address providing authorization (account or contract)
  /// - [nonce] Unique nonce to prevent replay attacks (typically from simulation)
  /// - [signatureExpirationLedger] Ledger number when signature expires (e.g., current + 100)
  /// - [signature] Cryptographic signature as XdrSCVal (initially void, filled during signing)
  SorobanAddressCredentials(
      this.address, this.nonce, this.signatureExpirationLedger, this.signature);

  /// Creates address credentials from their XDR representation.
  static SorobanAddressCredentials fromXdr(XdrSorobanAddressCredentials xdr) {
    return SorobanAddressCredentials(Address.fromXdr(xdr.address),
        xdr.nonce.int64, xdr.signatureExpirationLedger.uint32, xdr.signature);
  }

  /// Converts these address credentials to their XDR representation.
  XdrSorobanAddressCredentials toXdr() {
    return new XdrSorobanAddressCredentials(address.toXdr(), XdrInt64(nonce),
        XdrUint32(signatureExpirationLedger), signature);
  }
}

/// A single delegate node in a WITH_DELEGATES authorization tree (protocol 27+).
///
/// Each node holds:
/// - [address] The SCAddress of the delegate (account or contract; never muxed).
/// - [signature] The delegate's signature as an XdrSCVal (void until signed).
/// - [nestedDelegates] Child delegates authorized by this delegate.
///
/// Sorting invariant: within any [nestedDelegates] list, delegates are ordered
/// ascending by the lexicographic comparison of their complete XDR-encoded
/// [XdrSCAddress] bytes. Build trees with [SorobanDelegateDescriptor] and
/// [SorobanAuthorizationEntry.withDelegates]; that API enforces the sort order.
///
/// Signing semantics: all delegates at any depth sign the same preimage hash
/// as the top-level credentials; delegates carry no nonce or expiration.
/// Signing the same node twice with the same key appends a duplicate that the
/// host rejects.
class SorobanDelegateSignature {
  /// The SCAddress of this delegate.
  XdrSCAddress address;

  /// The delegate's signature (void until explicitly signed).
  XdrSCVal signature;

  /// Child delegates authorized by this delegate. Must be sorted ascending by
  /// the XDR-encoded bytes of each child's [address]; no duplicates within this list.
  List<SorobanDelegateSignature> nestedDelegates;

  SorobanDelegateSignature(this.address, this.signature, this.nestedDelegates);

  /// Creates a [SorobanDelegateSignature] from its XDR representation.
  static SorobanDelegateSignature fromXdr(XdrSorobanDelegateSignature xdr) {
    final nested = xdr.nestedDelegates
        .map((d) => SorobanDelegateSignature.fromXdr(d))
        .toList();
    return SorobanDelegateSignature(xdr.address, xdr.signature, nested);
  }

  /// Converts this delegate to its XDR representation.
  XdrSorobanDelegateSignature toXdr() {
    return XdrSorobanDelegateSignature(
      address,
      signature,
      nestedDelegates.map((d) => d.toXdr()).toList(),
    );
  }
}

/// Wraps the inner credentials and top-level delegate list for the
/// SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES arm (protocol 27+).
///
/// The [delegates] list must be sorted ascending by the XDR-encoded bytes of
/// each delegate's address and must not contain duplicate addresses at the
/// same level. Use [SorobanAuthorizationEntry.withDelegates] to construct
/// entries with correct sort order.
class SorobanAddressCredentialsWithDelegates {
  /// The core address credentials (address, nonce, expiration, top-level signature).
  SorobanAddressCredentials addressCredentials;

  /// Top-level delegates. Each element may itself carry nested delegates.
  /// Sorted ascending by XDR-encoded address bytes; no duplicates within this list.
  List<SorobanDelegateSignature> delegates;

  SorobanAddressCredentialsWithDelegates(this.addressCredentials, this.delegates);

  /// Creates from its XDR representation.
  static SorobanAddressCredentialsWithDelegates fromXdr(
      XdrSorobanAddressCredentialsWithDelegates xdr) {
    return SorobanAddressCredentialsWithDelegates(
      SorobanAddressCredentials.fromXdr(xdr.addressCredentials),
      xdr.delegates.map((d) => SorobanDelegateSignature.fromXdr(d)).toList(),
    );
  }

  /// Converts to XDR representation.
  XdrSorobanAddressCredentialsWithDelegates toXdr() {
    return XdrSorobanAddressCredentialsWithDelegates(
      addressCredentials.toXdr(),
      delegates.map((d) => d.toXdr()).toList(),
    );
  }
}

/// Authorization credentials for Soroban contract invocations.
///
/// Soroban supports four credential arms:
///
/// 1. Source Account Authorization (implicit):
///    - Used when the transaction source account authorizes the invocation.
///    - No explicit signature required.
///    - Created via [SorobanCredentials.forSourceAccount].
///
/// 2. Address Credentials (legacy, all protocol versions):
///    - Explicit per-address signature; preimage type ENVELOPE_TYPE_SOROBAN_AUTHORIZATION.
///    - Created via [SorobanCredentials.forAddress] or [SorobanCredentials.forAddressCredentials].
///    - This is the default and remains valid on all protocol versions.
///
/// 3. Address V2 Credentials (protocol 27+):
///    - Same body as Address but preimage type changes to
///      ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS (address-bound).
///    - Emitting this arm below protocol 27 invalidates the transaction.
///    - Created via [SorobanCredentials.forAddressV2].
///
/// 4. Address With Delegates Credentials (protocol 27+):
///    - Extends V2 with a recursive delegate tree.
///    - Emitting this arm below protocol 27 invalidates the transaction.
///    - Created via [SorobanCredentials.forAddressWithDelegates].
///    - Use [SorobanAuthorizationEntry.withDelegates] to build correctly sorted trees.
///
/// See also:
/// - [SorobanAuthorizationEntry] for complete authorization entry structure
/// - [AssembledTransaction.signAuthEntries] for signing workflows
class SorobanCredentials {
  // Exactly one of the four fields below is non-null, matching the active arm.
  SorobanAddressCredentials? addressCredentials;
  SorobanAddressCredentials? addressV2Credentials;
  SorobanAddressCredentialsWithDelegates? addressWithDelegatesCredentials;

  // null means SOURCE_ACCOUNT; set by the private _arm tracker
  XdrSorobanCredentialsType _arm;

  SorobanCredentials._(this._arm, {
    this.addressCredentials,
    this.addressV2Credentials,
    this.addressWithDelegatesCredentials,
  });

  /// Creates SorobanCredentials for contract invocation authorization.
  ///
  /// This constructor creates source-account credentials when
  /// [addressCredentials] is null, or legacy address credentials otherwise.
  ///
  /// For the new P27 arms use [forAddressV2] or [forAddressWithDelegates].
  SorobanCredentials({SorobanAddressCredentials? addressCredentials}) :
      _arm = addressCredentials != null
          ? XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS
          : XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT {
    if (addressCredentials != null) {
      this.addressCredentials = addressCredentials;
    }
  }

  /// Creates credentials for source account authorization.
  ///
  /// The transaction signature provides authorization; no explicit signature is required.
  static SorobanCredentials forSourceAccount() {
    return SorobanCredentials();
  }

  /// Creates legacy address-based credentials.
  ///
  /// Preimage type: ENVELOPE_TYPE_SOROBAN_AUTHORIZATION.
  /// Valid on all protocol versions.
  static SorobanCredentials forAddress(Address address, BigInt nonce,
      int signatureExpirationLedger, XdrSCVal signature) {
    SorobanAddressCredentials addressCredentials = SorobanAddressCredentials(
        address, nonce, signatureExpirationLedger, signature);
    return SorobanCredentials(addressCredentials: addressCredentials);
  }

  static SorobanCredentials forAddressCredentials(
      SorobanAddressCredentials addressCredentials) {
    return SorobanCredentials(addressCredentials: addressCredentials);
  }

  /// Creates ADDRESS_V2 credentials (protocol 27+).
  ///
  /// Preimage type: ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS.
  /// The preimage binds the top-level credential address.
  /// Emitting this arm on a network below protocol 27 invalidates the transaction.
  static SorobanCredentials forAddressV2(SorobanAddressCredentials credentials) {
    return SorobanCredentials._(
      XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
      addressV2Credentials: credentials,
    );
  }

  /// Creates ADDRESS_WITH_DELEGATES credentials (protocol 27+).
  ///
  /// Preimage type: ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS.
  /// Emitting this arm on a network below protocol 27 invalidates the transaction.
  /// Prefer [SorobanAuthorizationEntry.withDelegates] which enforces delegate sort order.
  static SorobanCredentials forAddressWithDelegates(
      SorobanAddressCredentialsWithDelegates credentials) {
    return SorobanCredentials._(
      XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES,
      addressWithDelegatesCredentials: credentials,
    );
  }

  /// The active credential arm discriminant.
  XdrSorobanCredentialsType get arm => _arm;

  /// Returns the inner [SorobanAddressCredentials] for any address arm,
  /// or null for SOURCE_ACCOUNT.
  SorobanAddressCredentials? get innerAddressCredentials {
    switch (_arm) {
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
        return addressCredentials;
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2:
        return addressV2Credentials;
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES:
        return addressWithDelegatesCredentials?.addressCredentials;
      default:
        return null;
    }
  }

  /// Creates Soroban credentials from their XDR representation.
  ///
  /// Throws if the discriminant is unrecognized.
  static SorobanCredentials fromXdr(XdrSorobanCredentials xdr) {
    switch (xdr.type) {
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
        if (xdr.address == null) {
          throw Exception('ADDRESS credentials missing address field');
        }
        return SorobanCredentials._(
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS,
          addressCredentials: SorobanAddressCredentials.fromXdr(xdr.address!),
        );
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2:
        if (xdr.addressV2 == null) {
          throw Exception('ADDRESS_V2 credentials missing addressV2 field');
        }
        return SorobanCredentials._(
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
          addressV2Credentials: SorobanAddressCredentials.fromXdr(xdr.addressV2!),
        );
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES:
        if (xdr.addressWithDelegates == null) {
          throw Exception('ADDRESS_WITH_DELEGATES credentials missing addressWithDelegates field');
        }
        return SorobanCredentials._(
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES,
          addressWithDelegatesCredentials:
              SorobanAddressCredentialsWithDelegates.fromXdr(xdr.addressWithDelegates!),
        );
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT:
        return SorobanCredentials._(
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT,
        );
      default:
        throw Exception(
          'Unknown SorobanCredentials discriminant: ${xdr.type}',
        );
    }
  }

  /// Converts these Soroban credentials to their XDR representation.
  XdrSorobanCredentials toXdr() {
    switch (_arm) {
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
        if (addressCredentials == null) {
          throw Exception('ADDRESS credentials missing addressCredentials');
        }
        return XdrSorobanCredentials.forAddressCredentials(
            addressCredentials!.toXdr());
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2:
        if (addressV2Credentials == null) {
          throw Exception('ADDRESS_V2 credentials missing addressV2Credentials');
        }
        return XdrSorobanCredentials.forAddressV2Credentials(
            addressV2Credentials!.toXdr());
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES:
        if (addressWithDelegatesCredentials == null) {
          throw Exception(
              'ADDRESS_WITH_DELEGATES credentials missing addressWithDelegatesCredentials');
        }
        return XdrSorobanCredentials.forAddressWithDelegatesCredentials(
            addressWithDelegatesCredentials!.toXdr());
      default:
        return XdrSorobanCredentials(
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT);
    }
  }
}

/// Represents a function that requires authorization in Soroban.
///
/// This class encapsulates different types of authorized operations that can occur
/// within Soroban smart contracts. An authorized function can be one of three types:
///
/// 1. Contract Function Call - Invoking a specific method on a deployed contract
/// 2. Create Contract (v1) - Deploying a new contract instance (legacy format)
/// 3. Create Contract (v2) - Deploying a new contract instance (current format)
///
/// Only one of the function types can be set at a time. Use the factory methods
/// to create instances for specific function types.
///
/// Example - Contract function authorization:
/// ```dart
/// final function = SorobanAuthorizedFunction.forContractFunction(
///   Address.forContractId('CABC...'),
///   'transfer',
///   [fromArg, toArg, amountArg],
/// );
/// ```
///
/// See also:
/// - [SorobanAuthorizedInvocation] for wrapping functions with sub-invocations
/// - [SorobanAuthorizationEntry] for complete authorization entries
class SorobanAuthorizedFunction {
  /// Contract function invocation details. Set when this represents a contract method call.
  XdrInvokeContractArgs? contractFn;

  /// Contract creation arguments (v1 format). Set when this represents contract deployment using legacy format.
  XdrCreateContractArgs? createContractHostFn;

  /// Contract creation arguments (v2 format). Set when this represents contract deployment using current format.
  XdrCreateContractArgsV2? createContractV2HostFn;

  /// Creates a SorobanAuthorizedFunction with one of the three function types.
  ///
  /// Exactly one parameter must be non-null.
  ///
  /// Parameters:
  /// - [contractFn] Arguments for invoking a contract function
  /// - [createContractHostFn] Arguments for creating a contract (v1)
  /// - [createContractV2HostFn] Arguments for creating a contract (v2)
  ///
  /// Throws:
  /// - ArgumentError If all parameters are null or if multiple are non-null
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

  /// Creates an authorized function for a contract method invocation.
  ///
  /// Use this when authorization is needed for calling a specific contract function.
  ///
  /// Parameters:
  /// - [contractAddress] Address of the contract containing the function
  /// - [functionName] Name of the function to invoke
  /// - [args] Arguments to pass to the function
  ///
  /// Returns: SorobanAuthorizedFunction configured for contract invocation
  ///
  /// Example:
  /// ```dart
  /// final function = SorobanAuthorizedFunction.forContractFunction(
  ///   Address.forContractId('CABC...'),
  ///   'approve',
  ///   [spenderArg, amountArg],
  /// );
  /// ```
  static SorobanAuthorizedFunction forContractFunction(
      Address contractAddress, String functionName, List<XdrSCVal> args) {
    XdrInvokeContractArgs cfn =
        XdrInvokeContractArgs(contractAddress.toXdr(), functionName, args);
    return SorobanAuthorizedFunction(contractFn: cfn);
  }

  /// Creates an authorized function for contract creation (v1 format).
  ///
  /// Use this for contract deployment operations using the legacy format.
  ///
  /// Parameters:
  /// - [createContractHostFn] Contract creation arguments
  ///
  /// Returns: SorobanAuthorizedFunction configured for contract creation
  static SorobanAuthorizedFunction forCreateContractHostFunction(
      XdrCreateContractArgs createContractHostFn) {
    return SorobanAuthorizedFunction(
        createContractHostFn: createContractHostFn);
  }

  /// Creates an authorized function for contract creation (v2 format).
  ///
  /// Use this for contract deployment operations using the current format.
  ///
  /// Parameters:
  /// - [createContractV2HostFn] Contract creation arguments (v2)
  ///
  /// Returns: SorobanAuthorizedFunction configured for contract creation
  static SorobanAuthorizedFunction forCreateContractV2HostFunction(
      XdrCreateContractArgsV2 createContractV2HostFn) {
    return SorobanAuthorizedFunction(
        createContractV2HostFn: createContractV2HostFn);
  }

  /// Deserializes a SorobanAuthorizedFunction from XDR format.
  ///
  /// Parameters:
  /// - [xdr] XDR representation of the authorized function
  ///
  /// Returns: Deserialized SorobanAuthorizedFunction
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

  /// Serializes this SorobanAuthorizedFunction to XDR format.
  ///
  /// Returns: XDR representation of this authorized function
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

/// Represents a tree of authorized function invocations in Soroban.
///
/// An authorized invocation consists of a primary function call that may trigger
/// additional contract calls (sub-invocations). This hierarchical structure is
/// necessary for complex contract interactions where one contract calls others.
///
/// For example, a token transfer might trigger sub-invocations:
/// 1. Main invocation: transfer function on token contract
/// 2. Sub-invocation 1: Check allowance on token contract
/// 3. Sub-invocation 2: Update balance on token contract
///
/// Each level of the tree must be properly authorized. The root invocation and all
/// sub-invocations form the complete authorization tree.
///
/// Fields:
/// - [function] The authorized function being invoked at this level
/// - [subInvocations] List of nested invocations triggered by this function
///
/// Example - Creating an invocation tree:
/// ```dart
/// // Create the main function
/// final mainFunction = SorobanAuthorizedFunction.forContractFunction(
///   Address.forContractId('CABC...'),
///   'transfer',
///   [fromArg, toArg, amountArg],
/// );
///
/// // Create sub-invocations if needed
/// final subFunction = SorobanAuthorizedFunction.forContractFunction(
///   Address.forContractId('CABC...'),
///   'check_balance',
///   [accountArg],
/// );
/// final subInvocation = SorobanAuthorizedInvocation(subFunction);
///
/// // Combine into tree
/// final rootInvocation = SorobanAuthorizedInvocation(
///   mainFunction,
///   subInvocations: [subInvocation],
/// );
/// ```
///
/// See also:
/// - [SorobanAuthorizedFunction] for function details
/// - [SorobanAuthorizationEntry] for complete authorization entries
class SorobanAuthorizedInvocation {
  /// The authorized function to be invoked.
  SorobanAuthorizedFunction function;

  /// List of additional invocations triggered by this function.
  /// Empty list if this function triggers no sub-invocations.
  List<SorobanAuthorizedInvocation> subInvocations =
      List<SorobanAuthorizedInvocation>.empty(growable: true);

  /// Creates a SorobanAuthorizedInvocation.
  ///
  /// Parameters:
  /// - [function] The function to be invoked
  /// - [subInvocations] Optional list of nested invocations (default: empty)
  SorobanAuthorizedInvocation(this.function,
      {List<SorobanAuthorizedInvocation>? subInvocations}) {
    if (subInvocations != null) {
      this.subInvocations = subInvocations;
    }
  }

  /// Deserializes a SorobanAuthorizedInvocation from XDR format.
  ///
  /// Recursively deserializes all sub-invocations in the tree.
  ///
  /// Parameters:
  /// - [xdr] XDR representation of the authorized invocation
  ///
  /// Returns: Deserialized SorobanAuthorizedInvocation with all sub-invocations
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

  /// Serializes this SorobanAuthorizedInvocation to XDR format.
  ///
  /// Recursively serializes all sub-invocations in the tree.
  ///
  /// Returns: XDR representation of this authorized invocation
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

/// Descriptor for a single delegate node when building a WITH_DELEGATES entry.
///
/// Used with [SorobanAuthorizationEntry.withDelegates] to specify the delegate
/// tree. The [signature] field defaults to void (the normal pre-signing state).
/// [nestedDelegates] lists child delegates authorized by this node.
///
/// Muxed addresses (M...) are not valid Soroban auth delegate addresses and
/// will be rejected by [SorobanAuthorizationEntry.withDelegates].
class SorobanDelegateDescriptor {
  /// The strkey of this delegate (G... account or C... contract).
  final String addressStrKey;

  /// Pre-filled signature for this node. Defaults to void.
  final XdrSCVal? signature;

  /// Child delegates authorized by this node (optional; defaults to none).
  final List<SorobanDelegateDescriptor> nestedDelegates;

  const SorobanDelegateDescriptor(
    this.addressStrKey, {
    this.signature,
    this.nestedDelegates = const [],
  });
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
///   if (entry.credentials.innerAddressCredentials != null) {
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

  /// Maximum depth for delegate tree traversal. Guards against pathological
  /// trees in forAddress routing.
  static const int _maxDelegateTraversalDepth = 128;

  /// Creates a SorobanAuthorizationEntry with credentials and invocation tree.
  ///
  /// This constructor combines authorization credentials with the function invocation
  /// tree to create a complete authorization entry. These entries are typically created
  /// by transaction simulation and then signed by the required parties.
  ///
  /// Parameters:
  /// - [credentials] Authorization credentials (source account or address-based)
  /// - [rootInvocation] The authorized function invocation tree with any sub-invocations
  SorobanAuthorizationEntry(this.credentials, this.rootInvocation);

  /// Creates an authorization entry from its XDR representation.
  static SorobanAuthorizationEntry fromXdr(XdrSorobanAuthorizationEntry xdr) {
    return SorobanAuthorizationEntry(
        SorobanCredentials.fromXdr(xdr.credentials),
        SorobanAuthorizedInvocation.fromXdr(xdr.rootInvocation));
  }

  /// Converts this authorization entry to its XDR representation.
  XdrSorobanAuthorizationEntry toXdr() {
    return XdrSorobanAuthorizationEntry(
        this.credentials.toXdr(), this.rootInvocation.toXdr());
  }

  /// Creates an authorization entry from base64-encoded XDR.
  static SorobanAuthorizationEntry fromBase64EncodedXdr(String xdr) {
    Uint8List bytes = base64Decode(xdr);
    return SorobanAuthorizationEntry.fromXdr(
        XdrSorobanAuthorizationEntry.decode(XdrDataInputStream(bytes)));
  }

  /// Converts this authorization entry to base64-encoded XDR format.
  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrSorobanAuthorizationEntry.encode(xdrOutputStream, this.toXdr());
    return base64Encode(xdrOutputStream.bytes);
  }

  /// Builds the XdrHashIDPreimage for this entry based on its credential arm.
  ///
  /// Arm selection:
  /// - ADDRESS -> ENVELOPE_TYPE_SOROBAN_AUTHORIZATION (address-independent preimage)
  /// - ADDRESS_V2 and ADDRESS_WITH_DELEGATES -> ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS
  ///   The address in the preimage is always the top-level credential address.
  ///
  /// [signatureExpirationLedger] must be set on the credentials BEFORE calling this
  /// method; the network reconstructs the preimage from the submitted credentials.
  ///
  /// Throws if the credentials are source-account or have an unknown arm.
  XdrHashIDPreimage buildPreimage(Network network) {
    final arm = credentials.arm;
    final inner = credentials.innerAddressCredentials;

    if (inner == null) {
      throw Exception(
          'Cannot build preimage for source-account credentials');
    }

    if (arm == XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS) {
      // Legacy preimage: no address binding
      final authPreimage = XdrHashIDPreimageSorobanAuthorization(
        XdrHash(network.networkId!),
        XdrInt64(inner.nonce),
        XdrUint32(inner.signatureExpirationLedger),
        rootInvocation.toXdr(),
      );
      final preimage = XdrHashIDPreimage(
          XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION);
      preimage.sorobanAuthorization = authPreimage;
      return preimage;
    } else if (arm == XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2 ||
               arm == XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES) {
      // Address-bound preimage; address is always the top-level credential address
      final authPreimage = XdrHashIDPreimageSorobanAuthorizationWithAddress(
        XdrHash(network.networkId!),
        XdrInt64(inner.nonce),
        XdrUint32(inner.signatureExpirationLedger),
        inner.address.toXdr(),
        rootInvocation.toXdr(),
      );
      final preimage = XdrHashIDPreimage(
          XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS);
      preimage.sorobanAuthorizationWithAddress = authPreimage;
      return preimage;
    } else {
      throw Exception(
          'Cannot build preimage for unknown credential arm: $arm');
    }
  }

  /// Encodes [preimage] and returns its SHA-256 hash (the payload to sign).
  static Uint8List _hashPreimage(XdrHashIDPreimage preimage) {
    final out = XdrDataOutputStream();
    XdrHashIDPreimage.encode(out, preimage);
    return Util.hash(Uint8List.fromList(out.bytes));
  }

  /// Appends [newSig] to the signature vector of [inner].
  ///
  /// If the current signature is void, it is replaced with a one-element vector.
  /// Otherwise the new element is appended to the existing vector.
  /// Non-void signatures are never silently overwritten.
  ///
  /// Callers are responsible for signing in ascending public-key order when
  /// G-address verification is required; the SDK appends in call order and does
  /// not sort. Signing the same node twice with the same key appends a duplicate
  /// that the host rejects.
  static void _appendSignature(
      SorobanAddressCredentials inner, AccountEd25519Signature newSig) {
    final existing = inner.signature;
    final List<XdrSCVal> sigs = List<XdrSCVal>.empty(growable: true);
    if (existing.vec != null) {
      sigs.addAll(existing.vec!);
    }
    sigs.add(newSig.toXdrSCVal());
    inner.signature = XdrSCVal.forVec(sigs);
  }

  /// Signs this authorization entry.
  ///
  /// [signatureExpirationLedger] must be set on the credentials before calling;
  /// the preimage is built from the current expiration value.
  ///
  /// All three address arms are supported:
  /// - ADDRESS: legacy preimage (no address binding)
  /// - ADDRESS_V2 and ADDRESS_WITH_DELEGATES: address-bound preimage
  ///
  /// The top-level signer and every delegate at any depth sign the same payload
  /// hash for a given entry.
  ///
  /// [forAddress]: if null, signs the top-level credentials. If non-null
  /// (strkey of a G... account or C... contract), the signature is routed
  /// into every node (top-level or delegate, depth-first) whose address matches.
  /// Throws if no node's address matches [forAddress].
  /// Muxed addresses (M...) are rejected as Soroban auth delegate targets.
  ///
  /// Append semantics: appends to existing signatures; void becomes one-element
  /// vector. The arm is preserved on write-back.
  ///
  /// Signing source-account credentials throws an exception.
  void sign(KeyPair signer, Network network, {String? forAddress}) {
    final arm = credentials.arm;

    if (arm == XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT) {
      throw Exception('Cannot sign source-account credentials');
    }

    final inner = credentials.innerAddressCredentials;
    if (inner == null) {
      throw Exception('No address credentials found for signing');
    }

    if (forAddress != null && forAddress.startsWith('M')) {
      throw Exception(
          'Muxed addresses (M...) are not valid Soroban auth targets; '
          'use the underlying G... account address instead');
    }

    // Build the payload once; all nodes (top-level and delegates) sign this same hash.
    final preimage = buildPreimage(network);
    final payload = _hashPreimage(preimage);
    final signatureBytes = signer.sign(payload);
    final sig = AccountEd25519Signature(signer.xdrPublicKey, signatureBytes);

    if (forAddress == null) {
      // Sign top-level credentials
      _appendSignature(inner, sig);
      _writeBackInnerCredentials(inner);
    } else {
      // Route to matching nodes in the delegate tree
      final matched = _routeSignatureToAddress(
          forAddress, inner, sig, 0);
      if (!matched) {
        throw Exception(
            'No node with address $forAddress found in this authorization entry');
      }
    }
  }

  /// Writes [inner] back into the credentials preserving the credential arm.
  void _writeBackInnerCredentials(SorobanAddressCredentials inner) {
    switch (credentials.arm) {
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
        credentials.addressCredentials = inner;
        break;
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2:
        credentials.addressV2Credentials = inner;
        break;
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES:
        // The inner credentials live inside the WithDelegates wrapper; they are
        // mutated in place so no explicit write-back is needed here.
        break;
      default:
        break;
    }
  }

  /// Encodes [addr] to XDR bytes for address comparison.
  static Uint8List _encodeAddress(XdrSCAddress addr) {
    final out = XdrDataOutputStream();
    XdrSCAddress.encode(out, addr);
    return Uint8List.fromList(out.bytes);
  }

  /// Returns the strkey representation of an [XdrSCAddress] for address matching.
  ///
  /// Only account (G...) and contract (C...) addresses are valid delegate targets.
  static String _xdrAddressToStrKey(XdrSCAddress addr) {
    if (addr.discriminant == XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT &&
        addr.accountId != null) {
      return KeyPair.fromXdrPublicKey(addr.accountId!.accountID).accountId;
    } else if (addr.discriminant == XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT &&
        addr.contractId != null) {
      return StrKey.encodeContractId(addr.contractId!.hash);
    }
    // Other address types (muxed, claimable balance, pool) return empty string
    // so they never match a forAddress target.
    return '';
  }

  /// Depth-first walk over the credential address and delegate tree.
  ///
  /// Appends [sig] to every node whose address strkey equals [targetStrKey].
  /// Returns true if at least one node was signed.
  ///
  /// Throws if [depth] exceeds [_maxDelegateTraversalDepth] to prevent
  /// unbounded recursion on pathological inputs.
  bool _routeSignatureToAddress(
      String targetStrKey,
      SorobanAddressCredentials topLevel,
      AccountEd25519Signature sig,
      int depth) {
    if (depth > _maxDelegateTraversalDepth) {
      throw Exception(
          'Delegate tree traversal depth limit ($_maxDelegateTraversalDepth) exceeded');
    }

    bool matched = false;

    // Check the top-level credential address (only at depth 0)
    if (depth == 0) {
      final topStrKey = _xdrAddressToStrKey(topLevel.address.toXdr());
      if (topStrKey == targetStrKey) {
        _appendSignature(topLevel, sig);
        _writeBackInnerCredentials(topLevel);
        matched = true;
      }

      // Walk delegates if present
      if (credentials.arm ==
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES) {
        final withDelegates = credentials.addressWithDelegatesCredentials!;
        for (final delegate in withDelegates.delegates) {
          if (_walkDelegate(targetStrKey, delegate, sig, depth + 1)) {
            matched = true;
          }
        }
      }
    }

    return matched;
  }

  /// Recursive walk of a delegate node and its nested delegates.
  bool _walkDelegate(
      String targetStrKey,
      SorobanDelegateSignature node,
      AccountEd25519Signature sig,
      int depth) {
    if (depth > _maxDelegateTraversalDepth) {
      throw Exception(
          'Delegate tree traversal depth limit ($_maxDelegateTraversalDepth) exceeded');
    }

    bool matched = false;
    final nodeStrKey = _xdrAddressToStrKey(node.address);
    if (nodeStrKey == targetStrKey) {
      _appendSignatureToDelegate(node, sig);
      matched = true;
    }

    for (final child in node.nestedDelegates) {
      if (_walkDelegate(targetStrKey, child, sig, depth + 1)) {
        matched = true;
      }
    }

    return matched;
  }

  /// Appends [sig] to the signature of delegate [node].
  static void _appendSignatureToDelegate(
      SorobanDelegateSignature node, AccountEd25519Signature sig) {
    final existing = node.signature;
    final List<XdrSCVal> sigs = List<XdrSCVal>.empty(growable: true);
    if (existing.vec != null) {
      sigs.addAll(existing.vec!);
    }
    sigs.add(sig.toXdrSCVal());
    node.signature = XdrSCVal.forVec(sigs);
  }

  /// Constructs a WITH_DELEGATES authorization entry from an existing ADDRESS or
  /// ADDRESS_V2 entry plus a list of delegate descriptors.
  ///
  /// Rules enforced:
  /// - [source] must be ADDRESS or ADDRESS_V2; throws if it is already WITH_DELEGATES
  ///   or SOURCE_ACCOUNT.
  /// - The top-level signature is defaulted to void (delegates-only pattern).
  /// - Each delegate's [address] must be a G... or C... strkey; M... is rejected.
  /// - Within each delegate array (top-level and each nestedDelegates), entries are
  ///   sorted ascending by the lexicographic comparison of the complete XDR-encoded
  ///   XdrSCAddress bytes. Strkey order is NOT used for sorting.
  /// - Duplicate addresses within one array (same encoded bytes) throw.
  ///   The same address appearing at different levels is legal.
  /// - [signatureExpirationLedger] must be provided; it is stamped onto the inner
  ///   credentials so the preimage is buildable immediately after this call.
  ///
  /// Returns: A new [SorobanAuthorizationEntry] with the ADDRESS_WITH_DELEGATES arm.
  static SorobanAuthorizationEntry withDelegates(
    SorobanAuthorizationEntry source,
    List<SorobanDelegateDescriptor> delegates,
    int signatureExpirationLedger,
  ) {
    final arm = source.credentials.arm;
    if (arm == XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES) {
      throw ArgumentError(
          'source entry is already ADDRESS_WITH_DELEGATES; '
          'cannot nest delegate trees');
    }
    if (arm == XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT) {
      throw ArgumentError(
          'source entry has source-account credentials; '
          'delegate trees require address credentials');
    }

    final sourceInner = source.credentials.innerAddressCredentials!;
    final innerCreds = SorobanAddressCredentials(
      sourceInner.address,
      sourceInner.nonce,
      signatureExpirationLedger,
      XdrSCVal.forVoid(), // top-level signature is void (delegates-only)
    );

    final sortedDelegates = _buildAndSortDelegates(delegates, depth: 0);
    final withDelegates = SorobanAddressCredentialsWithDelegates(
        innerCreds, sortedDelegates);

    return SorobanAuthorizationEntry(
      SorobanCredentials.forAddressWithDelegates(withDelegates),
      source.rootInvocation,
    );
  }

  /// Recursively builds [SorobanDelegateSignature] objects from descriptors,
  /// sorting each array by XDR-encoded address bytes and checking for duplicates.
  static List<SorobanDelegateSignature> _buildAndSortDelegates(
    List<SorobanDelegateDescriptor> descriptors, {
    required int depth,
  }) {
    if (depth > _maxDelegateTraversalDepth) {
      throw ArgumentError(
          'Delegate tree depth limit ($_maxDelegateTraversalDepth) exceeded '
          'during construction');
    }

    final List<_DelegateSortable> items = [];
    for (final desc in descriptors) {
      if (desc.addressStrKey.startsWith('M')) {
        throw ArgumentError(
            'Muxed addresses (M...) are not valid Soroban delegate addresses: '
            '${desc.addressStrKey}');
      }

      final xdrAddr = _strKeyToXdrAddress(desc.addressStrKey);
      final encodedAddr = _encodeAddress(xdrAddr);
      final nested = _buildAndSortDelegates(desc.nestedDelegates,
          depth: depth + 1);

      items.add(_DelegateSortable(
        encodedAddr: encodedAddr,
        delegate: SorobanDelegateSignature(
          xdrAddr,
          desc.signature ?? XdrSCVal.forVoid(),
          nested,
        ),
      ));
    }

    // Sort ascending by XDR-encoded address bytes (lexicographic)
    items.sort((a, b) {
      for (int i = 0; i < a.encodedAddr.length && i < b.encodedAddr.length; i++) {
        final cmp = a.encodedAddr[i].compareTo(b.encodedAddr[i]);
        if (cmp != 0) return cmp;
      }
      return a.encodedAddr.length.compareTo(b.encodedAddr.length);
    });

    // Check for duplicates within this array
    for (int i = 1; i < items.length; i++) {
      if (_bytesEqual(items[i - 1].encodedAddr, items[i].encodedAddr)) {
        throw ArgumentError(
            'Duplicate delegate address within one array: '
            '${descriptors[i].addressStrKey}');
      }
    }

    return items.map((e) => e.delegate).toList();
  }

  /// Converts a strkey (G... or C...) to an [XdrSCAddress].
  static XdrSCAddress _strKeyToXdrAddress(String strKey) {
    if (strKey.startsWith('G')) {
      return XdrSCAddress.forAccountId(strKey);
    } else if (strKey.startsWith('C')) {
      return XdrSCAddress.forContractId(strKey);
    } else {
      throw ArgumentError(
          'Invalid delegate address strkey (must start with G or C): $strKey');
    }
  }

  /// Returns true if [a] and [b] have identical contents.
  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Internal helper for sorting delegates by their XDR-encoded address bytes.
class _DelegateSortable {
  final Uint8List encodedAddr;
  final SorobanDelegateSignature delegate;

  _DelegateSortable({required this.encodedAddr, required this.delegate});
}

/// Ed25519 signature for Soroban authorization entries.
///
/// This class encapsulates a cryptographic signature used to prove authorization
/// in Soroban transactions. Each signature consists of:
/// - Public key: The Ed25519 public key that signed the data
/// - Signature bytes: The 64-byte Ed25519 signature
///
/// Signatures are automatically generated when signing authorization entries via
/// SorobanAuthorizationEntry.sign(). The signature format conforms to Stellar's
/// Ed25519 signature scheme.
///
/// The signature is serialized to XdrSCVal as a map with two entries:
/// - "public_key": The 32-byte public key
/// - "signature": The 64-byte signature
///
/// Fields:
/// - [publicKey] The Ed25519 public key in XDR format
/// - [signatureBytes] The 64-byte signature
///
/// Example - Usage in authorization:
/// ```dart
/// // Create authorization entry
/// final authEntry = simulation.getSorobanAuth()![0];
///
/// // Sign with keypair (signature created automatically)
/// authEntry.sign(signerKeyPair, network);
///
/// // The signature is embedded in the auth entry credentials
/// final credentials = authEntry.credentials.innerAddressCredentials;
/// print('Signature embedded in auth entry');
/// ```
///
/// Example - Manual signature construction (advanced):
/// ```dart
/// // Typically not needed - use authEntry.sign() instead
/// final publicKey = signerKeyPair.xdrPublicKey;
/// final signatureBytes = signerKeyPair.sign(payload);
///
/// final signature = AccountEd25519Signature(publicKey, signatureBytes);
/// final scVal = signature.toXdrSCVal();
/// ```
///
/// See also:
/// - [SorobanAuthorizationEntry.sign] for signing auth entries
/// - [KeyPair.sign] for creating signatures
class AccountEd25519Signature {
  /// The Ed25519 public key that created this signature.
  XdrPublicKey publicKey;

  /// The 64-byte Ed25519 signature bytes.
  Uint8List signatureBytes;

  /// Creates an AccountEd25519Signature.
  ///
  /// Parameters:
  /// - [publicKey] The Ed25519 public key in XDR format
  /// - [signatureBytes] The 64-byte signature
  AccountEd25519Signature(this.publicKey, this.signatureBytes);

  /// Converts this signature to XdrSCVal format for Soroban.
  ///
  /// Creates a map with two entries:
  /// - "public_key": The public key bytes
  /// - "signature": The signature bytes
  ///
  /// Returns: XdrSCVal map containing the signature data
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
