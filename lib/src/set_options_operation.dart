// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'key_pair.dart';
import 'xdr/xdr_signing.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_type.dart';

/// Represents <a href="https://developers.stellar.org/docs/start/list-of-operations/#set-options">SetOptions</a> operation.
/// See: <a href="https://developers.stellar.org/docs/start/list-of-operations/">List of Operations</a>
class SetOptionsOperation extends Operation {
  String? _inflationDestination;
  int? _clearFlags;
  int? _setFlags;
  int? _masterKeyWeight;
  int? _lowThreshold;
  int? _mediumThreshold;
  int? _highThreshold;
  String? _homeDomain;
  XdrSignerKey? _signer;
  int? _signerWeight;

  SetOptionsOperation(
      String? inflationDestination,
      int? clearFlags,
      int? setFlags,
      int? masterKeyWeight,
      int? lowThreshold,
      int? mediumThreshold,
      int? highThreshold,
      String? homeDomain,
      XdrSignerKey? signer,
      int? signerWeight) {
    this._inflationDestination = inflationDestination;
    this._clearFlags = clearFlags;
    this._setFlags = setFlags;
    this._masterKeyWeight = masterKeyWeight;
    this._lowThreshold = lowThreshold;
    this._mediumThreshold = mediumThreshold;
    this._highThreshold = highThreshold;
    this._homeDomain = homeDomain;
    this._signer = signer;
    this._signerWeight = signerWeight;
  }

  /// Account Id of the inflation destination.
  String? get inflationDestination => _inflationDestination;

  /// Indicates which flags to clear. For details about the flags, please refer to the <a href="https://www.stellar.org/developers/learn/concepts/accounts.html" target="_blank">accounts doc</a>.
  int? get clearFlags => _clearFlags;

  /// Indicates which flags to set. For details about the flags, please refer to the <a href="https://www.stellar.org/developers/learn/concepts/accounts.html" target="_blank">accounts doc</a>.
  int? get setFlags => _setFlags;

  /// Weight of the master key.
  int? get masterKeyWeight => _masterKeyWeight;

  /// A number from 0-255 representing the threshold this account sets on all operations it performs that have <a href="https://www.stellar.org/developers/learn/concepts/multi-sig.html" target="_blank">a low threshold</a>.
  int? get lowThreshold => _lowThreshold;

  /// A number from 0-255 representing the threshold this account sets on all operations it performs that have <a href="https://www.stellar.org/developers/learn/concepts/multi-sig.html" target="_blank">a medium threshold</a>.
  int? get mediumThreshold => _mediumThreshold;

  /// A number from 0-255 representing the threshold this account sets on all operations it performs that have <a href="https://www.stellar.org/developers/learn/concepts/multi-sig.html" target="_blank">a high threshold</a>.
  int? get highThreshold => _highThreshold;

  /// The home domain of an account.
  String? get homeDomain => _homeDomain;

  /// Additional signer added/removed in this operation.
  XdrSignerKey? get signer => _signer;

  /// Additional signer weight. The signer is deleted if the weight is 0.
  int? get signerWeight => _signerWeight;

  @override
  XdrOperationBody toOperationBody() {
    XdrSetOptionsOp op = new XdrSetOptionsOp();
    if (inflationDestination != null) {
      op.inflationDest = new XdrAccountID(
          KeyPair.fromAccountId(this.inflationDestination!).xdrPublicKey);
    }
    if (clearFlags != null) {
      op.clearFlags = new XdrUint32(this.clearFlags!);
    }
    if (setFlags != null) {
      op.setFlags = new XdrUint32(this.setFlags!);
    }
    if (masterKeyWeight != null) {
      op.masterWeight = new XdrUint32(masterKeyWeight!);
    }
    if (lowThreshold != null) {
      op.lowThreshold = new XdrUint32(lowThreshold!);
    }
    if (mediumThreshold != null) {
      op.medThreshold = new XdrUint32(mediumThreshold!);
    }
    if (highThreshold != null) {
      op.highThreshold = new XdrUint32(highThreshold!);
    }
    if (homeDomain != null) {
      op.homeDomain = new XdrString32(this.homeDomain!);
    }
    if (signer != null) {

      XdrUint32 weight = new XdrUint32(signerWeight! & 0xFF);
      op.signer = new XdrSigner(this.signer!, weight);
    }

    XdrOperationBody body = new XdrOperationBody(XdrOperationType.SET_OPTIONS);
    body.setOptionsOp = op;
    return body;
  }

  /// Builds SetOptions operation.
  static SetOptionsOperationBuilder builder(XdrSetOptionsOp op) {
    SetOptionsOperationBuilder builder = SetOptionsOperationBuilder();

    if (op.inflationDest != null) {
      builder = builder.setInflationDestination(
          KeyPair.fromXdrPublicKey(op.inflationDest!.accountID).accountId);
    }
    if (op.clearFlags != null) {
      builder = builder.setClearFlags(op.clearFlags!.uint32);
    }
    if (op.setFlags != null) {
      builder = builder.setSetFlags(op.setFlags!.uint32);
    }
    if (op.masterWeight != null) {
      builder = builder.setMasterKeyWeight(op.masterWeight!.uint32);
    }
    if (op.lowThreshold != null) {
      builder = builder.setLowThreshold(op.lowThreshold!.uint32);
    }
    if (op.medThreshold != null) {
      builder = builder.setMediumThreshold(op.medThreshold!.uint32);
    }
    if (op.highThreshold != null) {
      builder = builder.setHighThreshold(op.highThreshold!.uint32);
    }
    if (op.homeDomain != null) {
      builder = builder.setHomeDomain(op.homeDomain!.string32);
    }
    if (op.signer != null) {
      builder =
          builder.setSigner(op.signer!.key, op.signer!.weight.uint32 & 0xFF);
    }

    return builder;
  }
}

class SetOptionsOperationBuilder {
  String? _inflationDestination;
  int? _clearFlags;
  int? _setFlags;
  int? _masterKeyWeight;
  int? _lowThreshold;
  int? _mediumThreshold;
  int? _highThreshold;
  String? _homeDomain;
  XdrSignerKey? _signer;
  int? _signerWeight;
  MuxedAccount? _sourceAccount;

  SetOptionsOperationBuilder();

  /// Sets the inflation destination for the account.
  SetOptionsOperationBuilder setInflationDestination(
      String inflationDestination) {
    this._inflationDestination = inflationDestination;
    return this;
  }

  /// Clears the given flags from the account.
  SetOptionsOperationBuilder setClearFlags(int clearFlags) {
    this._clearFlags = clearFlags;
    return this;
  }

  /// Sets the given flags on the account.
  SetOptionsOperationBuilder setSetFlags(int setFlags) {
    this._setFlags = setFlags;
    return this;
  }

  /// Weight of the master key.
  SetOptionsOperationBuilder setMasterKeyWeight(int masterKeyWeight) {
    this._masterKeyWeight = masterKeyWeight;
    return this;
  }

  /// A number from 0-255 representing the threshold this account sets on all operations it performs that have a low threshold.
  SetOptionsOperationBuilder setLowThreshold(int lowThreshold) {
    this._lowThreshold = lowThreshold;
    return this;
  }

  /// A number from 0-255 representing the threshold this account sets on all operations it performs that have a medium threshold.
  SetOptionsOperationBuilder setMediumThreshold(int mediumThreshold) {
    this._mediumThreshold = mediumThreshold;
    return this;
  }

  /// A number from 0-255 representing the threshold this account sets on all operations it performs that have a high threshold.
  SetOptionsOperationBuilder setHighThreshold(int highThreshold) {
    this._highThreshold = highThreshold;
    return this;
  }

  /// Sets the account's home domain address used in <a href="https://www.stellar.org/developers/learn/concepts/federation.html" target="_blank">Federation</a>.
  SetOptionsOperationBuilder setHomeDomain(String homeDomain) {
    if (homeDomain.length > 32) {
      throw new Exception("Home domain must be <= 32 characters");
    }
    this._homeDomain = homeDomain;
    return this;
  }

  /// Add, update, or remove a signer from the account. Signer is deleted if the weight = 0;
  SetOptionsOperationBuilder setSigner(XdrSignerKey signer, int weight) {
    this._signer = signer;
    _signerWeight = weight & 0xFF;
    return this;
  }

  /// Sets the source account for this operation.
  SetOptionsOperationBuilder setSourceAccount(String sourceAccountId) {
    _sourceAccount = MuxedAccount.fromAccountId(sourceAccountId);
    return this;
  }

  /// Sets the muxed source account for this operation.
  SetOptionsOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _sourceAccount = sourceAccount;
    return this;
  }

  /// Builds a SetOptionsOperation.
  SetOptionsOperation build() {
    SetOptionsOperation operation = new SetOptionsOperation(
        _inflationDestination,
        _clearFlags,
        _setFlags,
        _masterKeyWeight,
        _lowThreshold,
        _mediumThreshold,
        _highThreshold,
        _homeDomain,
        _signer,
        _signerWeight);
    if (_sourceAccount != null) {
      operation.sourceAccount = _sourceAccount;
    }
    return operation;
  }
}
