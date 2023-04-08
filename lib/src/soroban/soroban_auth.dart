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

/// Represents a single address in the Stellar network.
///
/// An address can represent an account or a contract.
/// To create an address, call [Address.new]
/// or use [Address.forAccountId] to create an Address for a given accountId
/// or use [Address.forContractId] to create an Address for a given contractId
/// or use [Address.fromXdr] to create an Address for a given [XdrSCAddress].
class Address {

  static const int TYPE_ACCOUNT = 0;
  static const int TYPE_CONTRACT = 1;

  int _type;

  /// The type of the Address (TYPE_ACCOUNT or TYPE_CONTRACT).
  get type => _type;

  /// The id of the account if type is TYPE_ACCOUNT otherwise null.
  String? accountId;

  /// The id of the contract if type is TYPE_CONTRACT otherwise null.
  String? contractId;

  /// Constructs an [Address] for the given [type] which can be [Address.TYPE_ACCOUNT] or [Address.TYPE_CONTRACT].
  ///
  /// If [Address.TYPE_ACCOUNT] one must provide [accountId].
  /// If [Address.TYPE_CONTRACT] one must provide [contractId].
  Address(this._type, {this.accountId, this.contractId}) {
    if (this._type != TYPE_ACCOUNT && this._type != TYPE_CONTRACT) {
      throw new Exception("unknown type");
    }

    if (this._type == TYPE_ACCOUNT && this.accountId == null) {
      throw new Exception("invalid arguments");
    }

    if (this._type == TYPE_CONTRACT && this.contractId == null) {
      throw new Exception("invalid arguments");
    }
  }

  /// Constructs an [Address] of type [Address.TYPE_ACCOUNT] for the given [accountId].
  static Address forAccountId(String accountId) {
    return Address(TYPE_ACCOUNT, accountId: accountId);
  }

  /// Constructs an [Address] of type [Address.TYPE_CONTRACT] for the given [contractId].
  static Address forContractId(String contractId) {
    return Address(TYPE_CONTRACT, contractId: contractId);
  }

  /// Constructs an [Address] from the given [xdr].
  static Address fromXdr(XdrSCAddress xdr) {
    if (xdr.discriminant == XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT) {
      KeyPair kp = KeyPair.fromXdrPublicKey(xdr.accountId!.accountID);
      return Address(TYPE_ACCOUNT, accountId: kp.accountId);
    } else if (xdr.discriminant == XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT) {
      return Address(TYPE_CONTRACT,
          contractId: Util.bytesToHex(xdr.contractId!.hash));
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
    } else {
      throw Exception("unknown address type " + _type.toString());
    }
  }

  /// Returns a [XdrSCVal] containing an [XdrSCObject] for this [Address].
  XdrSCVal toXdrSCVal() {
    return XdrSCVal.forAddress(toXdr());
  }
}

/// Represents an authorized invocation.
///
/// See Soroban Documentation - Authorization <https://soroban.stellar.org/docs/learn/authorization> for more information.
class AuthorizedInvocation {

  /// The id of the contract to invoke.
  String contractId;

  /// The name of the contract function to invoke.
  String functionName;

  /// The list of arguments to pass to the contract function to be called.
  List<XdrSCVal> args = List<XdrSCVal>.empty(growable: true);

  /// The list of sub-invocations to pass to the contract function to be called.
  List<AuthorizedInvocation> subInvocations = List<AuthorizedInvocation>.empty(
      growable:true);

  /// Constructs an [AuthorizedInvocation] object for the given [contractId]
  /// and [functionName] of the contract function to be called.
  ///
  /// Optional list of [args] for the contract function to be called
  /// and optional list of [subInvocations] can be provided.
  AuthorizedInvocation(this.contractId, this.functionName,
      {List<XdrSCVal>? args, List<AuthorizedInvocation>? subInvocations}) {
    if (args != null) {
      this.args = args;
    }
    if (subInvocations != null) {
      this.subInvocations = subInvocations;
    }
  }

  /// Constructs an [AuthorizedInvocation] from the given [xdr].
  static AuthorizedInvocation fromXdr(XdrAuthorizedInvocation xdr) {
    List<AuthorizedInvocation> subInvocations =
        List<AuthorizedInvocation>.empty(growable: true);
    for (XdrAuthorizedInvocation subXdr in xdr.subInvocations) {
      subInvocations.add(AuthorizedInvocation.fromXdr(subXdr));
    }
    String contractId = Util.bytesToHex(xdr.contractID.hash);
    return AuthorizedInvocation(contractId, xdr.functionName,
        args: xdr.args, subInvocations: subInvocations);
  }

  /// Returns an [XdrAuthorizedInvocation] object created from this [AuthorizedInvocation] object.
  XdrAuthorizedInvocation toXdr() {
    List<XdrAuthorizedInvocation> xdrSubs =
        List<XdrAuthorizedInvocation>.empty(growable: true);
    for (AuthorizedInvocation sub in this.subInvocations) {
      xdrSubs.add(sub.toXdr());
    }
    return new XdrAuthorizedInvocation(
        XdrHash(Util.hexToBytes(contractId)), functionName, args, xdrSubs);
  }
}

/// Represents a contract authorization.
///
/// See Soroban Documentation - Authorization <https://soroban.stellar.org/docs/learn/authorization> for more information.
class ContractAuth {

  /// The root authorized invocation.
  AuthorizedInvocation rootInvocation;

  /// The signature arguments.
  List<XdrSCVal> signatureArgs = List<XdrSCVal>.empty(growable: true);


  Address? address;
  int? nonce;

  ContractAuth(this.rootInvocation,
      {List<XdrSCVal>? signatureArgs, this.address, this.nonce}) {
    if (signatureArgs != null) {
      this.signatureArgs = signatureArgs;
    }
  }

  /// Signs the contract authorization.
  ///
  /// The signature will be added to the [signatureArgs]
  /// For custom accounts, this signature format may not be applicable.
  /// See Soroban Documentation - Stellar Account Signatures <https://soroban.stellar.org/docs/how-to-guides/invoking-contracts-with-transactions#stellar-account-signatures>
  void sign(KeyPair signer, Network network) {
    if (address == null || nonce == null) {
      throw Exception("address and nonce must be set.");
    }

    XdrHashIDPreimageContractAuth contractAuthPreimageXdr =
        XdrHashIDPreimageContractAuth(XdrHash(network.networkId!),
            XdrUint64(nonce!), rootInvocation.toXdr());
    XdrHashIDPreimage rootInvocationPreimage =
        XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_AUTH);
    rootInvocationPreimage.contractAuth = contractAuthPreimageXdr;
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrHashIDPreimage.encode(xdrOutputStream, rootInvocationPreimage);
    Uint8List payload = Util.hash(Uint8List.fromList(xdrOutputStream.bytes));
    Uint8List signatureBytes = signer.sign(payload);
    AccountEd25519Signature signature =
        AccountEd25519Signature(signer.xdrPublicKey, signatureBytes);
    signatureArgs.add(signature.toXdrSCVal());
  }

  /// Constructs a [ContractAuth] from base64 encoded [xdr].
  static ContractAuth fromBase64EncodedXdr(String xdr) {
    Uint8List bytes = base64Decode(xdr);
    return ContractAuth.fromXdr(
        XdrContractAuth.decode(XdrDataInputStream(bytes)));
  }

  /// Constructs a [ContractAuth] from [xdr].
  static ContractAuth fromXdr(XdrContractAuth xdr) {
    AuthorizedInvocation rootInvocation =
        AuthorizedInvocation.fromXdr(xdr.rootInvocation);
    Address? address;
    int? nonce;
    if (xdr.addressWithNonce != null) {
      address = Address.fromXdr(xdr.addressWithNonce!.address);
      nonce = xdr.addressWithNonce!.nonce.uint64;
    }

    // PATCH: See: https://discord.com/channels/897514728459468821/1076723574884282398/1078095366890729595
    List<XdrSCVal> argsArr = List<XdrSCVal>.empty(growable: true);
    if (xdr.signatureArgs.length > 0) {
      XdrSCVal innerVal = xdr.signatureArgs[0];
      if (innerVal.vec != null) {
        argsArr = innerVal.vec!;
      } else {
        argsArr = xdr.signatureArgs;
      }
    }
    return new ContractAuth(rootInvocation,
        signatureArgs: argsArr, address: address, nonce: nonce);
  }

  /// Constructs a list of [ContractAuth] from a list of [XdrContractAuth].
  static List<ContractAuth> fromXdrList(List<XdrContractAuth> xdrAuth) {
    List<ContractAuth> result = List<ContractAuth>.empty(growable: true);
    for (XdrContractAuth next in xdrAuth) {
      result.add(ContractAuth.fromXdr(next));
    }
    return result;
  }

  /// Creates an [XdrContractAuth] from this.
  XdrContractAuth toXdr() {
    XdrAddressWithNonce? addressWithNonce;
    if (address != null && nonce != null) {
      addressWithNonce =
          XdrAddressWithNonce(address!.toXdr(), XdrUint64(nonce!));
    }

    // See: https://discord.com/channels/897514728459468821/1076723574884282398/1078095366890729595
    List<XdrSCVal> sigArgs = List<XdrSCVal>.empty(growable: true);
    if (signatureArgs.length > 0) {
      sigArgs.add(XdrSCVal.forVec(signatureArgs));
    }
    return new XdrContractAuth(
        addressWithNonce, rootInvocation.toXdr(), sigArgs);
  }

  /// Creates a list of [XdrContractAuth] from a list of [ContractAuth].
  static List<XdrContractAuth> toXdrList(List<ContractAuth> auth) {
    List<XdrContractAuth> result = List<XdrContractAuth>.empty(growable: true);
    for (ContractAuth next in auth) {
      result.add(next.toXdr());
    }
    return result;
  }
}

/// Represents a signature used by [ContractAuth].
class AccountEd25519Signature {
  XdrPublicKey publicKey;
  Uint8List signatureBytes;

  AccountEd25519Signature(this.publicKey, this.signatureBytes);

  XdrSCVal toXdrSCVal() {
    XdrSCVal pkVal = XdrSCVal.forBytes(publicKey.getEd25519()!.uint256);
    XdrSCVal sigVal = XdrSCVal.forBytes(signatureBytes);
    XdrSCMapEntry pkEntry = XdrSCMapEntry(
        XdrSCVal.forSymbol("public_key"), pkVal);
    XdrSCMapEntry sigEntry = XdrSCMapEntry(
        XdrSCVal.forSymbol("signature"), sigVal);
    return XdrSCVal.forMap([pkEntry, sigEntry]);
  }
}
