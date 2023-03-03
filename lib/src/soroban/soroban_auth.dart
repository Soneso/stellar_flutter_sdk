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
/// An address can represent an account or a contract.
class Address {
  static const int TYPE_ACCOUNT = 0;
  static const int TYPE_CONTRACT = 1;

  int _type;
  get type => _type;

  String? accountId;
  String? contractId;

  Address(this._type, {this.accountId, this.contractId});

  static Address forAccountId(String accountId) {
    return Address(TYPE_ACCOUNT, accountId: accountId);
  }

  static Address forContractId(String contractId) {
    return Address(TYPE_CONTRACT, contractId: contractId);
  }

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

  XdrSCVal toXdrSCVal() {
    return XdrSCVal.forObject(XdrSCObject.forAddress(toXdr()));
  }
}

/// Represents an authorized invocation.
/// See Soroban Documentation - Authorization <https://soroban.stellar.org/docs/learn/authorization> for more information.
class AuthorizedInvocation {
  String contractId; // The ID of the contract to invoke.
  String functionName; // The name of the function to invoke.
  List<XdrSCVal> args = List<XdrSCVal>.empty(
      growable:
          true); // The arguments to pass to the function. array of XdrSCVal.
  List<AuthorizedInvocation> subInvocations = List<AuthorizedInvocation>.empty(
      growable:
          true); // The sub-invocations to pass to the function. array of AuthorizedInvocation.

  AuthorizedInvocation(this.contractId, this.functionName,
      {List<XdrSCVal>? args, List<AuthorizedInvocation>? subInvocations}) {
    if (args != null) {
      this.args = args;
    }
    if (subInvocations != null) {
      this.subInvocations = subInvocations;
    }
  }

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
/// See Soroban Documentation - Authorization <https://soroban.stellar.org/docs/learn/authorization> for more information.
class ContractAuth {
  AuthorizedInvocation rootInvocation;
  List<XdrSCVal> signatureArgs = List<XdrSCVal>.empty(growable: true);
  Address? address;
  int? nonce;

  ContractAuth(this.rootInvocation,
      {List<XdrSCVal>? signatureArgs, this.address, this.nonce}) {
    if (signatureArgs != null) {
      this.signatureArgs = signatureArgs;
    }
  }

  /// Sign the contract authorization, the signature will be added to the `signatureArgs`
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

  static ContractAuth fromBase64EncodedXdr(String xdr) {
    Uint8List bytes = base64Decode(xdr);
    return ContractAuth.fromXdr(
        XdrContractAuth.decode(XdrDataInputStream(bytes)));
  }

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
      if (innerVal.obj != null && innerVal.obj!.vec != null) {
        argsArr = innerVal.obj!.vec!;
      } else {
        argsArr = xdr.signatureArgs;
      }
    }
    return new ContractAuth(rootInvocation,
        signatureArgs: argsArr, address: address, nonce: nonce);
  }

  static List<ContractAuth> fromXdrList(List<XdrContractAuth> xdrAuth) {
    List<ContractAuth> result = List<ContractAuth>.empty(growable: true);
    for (XdrContractAuth next in xdrAuth) {
      result.add(ContractAuth.fromXdr(next));
    }
    return result;
  }

  XdrContractAuth toXdr() {
    XdrAddressWithNonce? addressWithNonce;
    if (address != null && nonce != null) {
      addressWithNonce =
          XdrAddressWithNonce(address!.toXdr(), XdrUint64(nonce!));
    }

    // See: https://discord.com/channels/897514728459468821/1076723574884282398/1078095366890729595
    List<XdrSCVal> sigArgs = List<XdrSCVal>.empty(growable: true);
    if (signatureArgs.length > 0) {
      XdrSCObject obj = XdrSCObject.forVec(signatureArgs);
      XdrSCVal val = XdrSCVal.forObject(obj);
      sigArgs.add(val);
    }
    return new XdrContractAuth(
        addressWithNonce, rootInvocation.toXdr(), sigArgs);
  }

  static List<XdrContractAuth> toXdrList(List<ContractAuth> auth) {
    List<XdrContractAuth> result = List<XdrContractAuth>.empty(growable: true);
    for (ContractAuth next in auth) {
      result.add(next.toXdr());
    }
    return result;
  }
}

class AccountEd25519Signature {
  XdrPublicKey publicKey;
  Uint8List signatureBytes;

  AccountEd25519Signature(this.publicKey, this.signatureBytes);

  XdrSCVal toXdrSCVal() {
    XdrSCObject pkObj = XdrSCObject.forBytes(publicKey.getEd25519()!.uint256);
    XdrSCObject sigObj = XdrSCObject.forBytes(signatureBytes);
    XdrSCMapEntry pkEntry = XdrSCMapEntry(
        XdrSCVal.forSymbol("public_key"), XdrSCVal.forObject(pkObj));
    XdrSCMapEntry sigEntry = XdrSCMapEntry(
        XdrSCVal.forSymbol("signature"), XdrSCVal.forObject(sigObj));
    XdrSCObject resultObj = XdrSCObject.forMap([pkEntry, sigEntry]);
    return XdrSCVal.forObject(resultObj);
  }
}
