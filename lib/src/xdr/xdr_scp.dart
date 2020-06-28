// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_type.dart';
import 'xdr_data_io.dart';
import 'xdr_network.dart';
import 'xdr_signing.dart';

class XdrSCPStatementType {
  final _value;
  const XdrSCPStatementType._internal(this._value);
  toString() => 'SCPStatementType.$_value';
  XdrSCPStatementType(this._value);
  get value => this._value;

  static const SCP_ST_PREPARE = const XdrSCPStatementType._internal(0);
  static const SCP_ST_CONFIRM = const XdrSCPStatementType._internal(1);
  static const SCP_ST_EXTERNALIZE = const XdrSCPStatementType._internal(2);
  static const SCP_ST_NOMINATE = const XdrSCPStatementType._internal(3);

  static XdrSCPStatementType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SCP_ST_PREPARE;
      case 1:
        return SCP_ST_CONFIRM;
      case 2:
        return SCP_ST_EXTERNALIZE;
      case 3:
        return SCP_ST_NOMINATE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCPStatementType value) {
    stream.writeInt(value.value);
  }
}

class XdrSCPBallot {
  XdrSCPBallot();
  XdrUint32 _counter;
  XdrUint32 get counter => this._counter;
  set counter(XdrUint32 value) => this._counter = value;

  XdrValue _value;
  XdrValue get value => this._value;
  set value(XdrValue value) => this._value = value;

  static void encode(
      XdrDataOutputStream stream, XdrSCPBallot encodedSCPBallot) {
    XdrUint32.encode(stream, encodedSCPBallot.counter);
    XdrValue.encode(stream, encodedSCPBallot.value);
  }

  static XdrSCPBallot decode(XdrDataInputStream stream) {
    XdrSCPBallot decodedSCPBallot = XdrSCPBallot();
    decodedSCPBallot.counter = XdrUint32.decode(stream);
    decodedSCPBallot.value = XdrValue.decode(stream);
    return decodedSCPBallot;
  }
}

class XdrSCPEnvelope {
  XdrSCPEnvelope();
  XdrSCPStatement _statement;
  XdrSCPStatement get statement => this._statement;
  set statement(XdrSCPStatement value) => this._statement = value;

  XdrSignature _signature;
  XdrSignature get signature => this._signature;
  set signature(XdrSignature value) => this._signature = value;

  static void encode(
      XdrDataOutputStream stream, XdrSCPEnvelope encodedSCPEnvelope) {
    XdrSCPStatement.encode(stream, encodedSCPEnvelope.statement);
    XdrSignature.encode(stream, encodedSCPEnvelope.signature);
  }

  static XdrSCPEnvelope decode(XdrDataInputStream stream) {
    XdrSCPEnvelope decodedSCPEnvelope = XdrSCPEnvelope();
    decodedSCPEnvelope.statement = XdrSCPStatement.decode(stream);
    decodedSCPEnvelope.signature = XdrSignature.decode(stream);
    return decodedSCPEnvelope;
  }
}

class XdrSCPNomination {
  XdrSCPNomination();
  XdrHash _quorumSetHash;
  XdrHash get quorumSetHash => this._quorumSetHash;
  set quorumSetHash(XdrHash value) => this._quorumSetHash = value;

  List<XdrValue> _votes;
  List<XdrValue> get votes => this._votes;
  set votes(List<XdrValue> value) => this._votes = value;

  List<XdrValue> _accepted;
  List<XdrValue> get accepted => this._accepted;
  set accepted(List<XdrValue> value) => this._accepted = value;

  static void encode(
      XdrDataOutputStream stream, XdrSCPNomination encodedSCPNomination) {
    XdrHash.encode(stream, encodedSCPNomination.quorumSetHash);
    int votessize = encodedSCPNomination.votes.length;
    stream.writeInt(votessize);
    for (int i = 0; i < votessize; i++) {
      XdrValue.encode(stream, encodedSCPNomination.votes[i]);
    }
    int acceptedsize = encodedSCPNomination.accepted.length;
    stream.writeInt(acceptedsize);
    for (int i = 0; i < acceptedsize; i++) {
      XdrValue.encode(stream, encodedSCPNomination.accepted[i]);
    }
  }

  static XdrSCPNomination decode(XdrDataInputStream stream) {
    XdrSCPNomination decodedSCPNomination = XdrSCPNomination();
    decodedSCPNomination.quorumSetHash = XdrHash.decode(stream);
    int votessize = stream.readInt();
    decodedSCPNomination.votes = List<XdrValue>(votessize);
    for (int i = 0; i < votessize; i++) {
      decodedSCPNomination.votes[i] = XdrValue.decode(stream);
    }
    int acceptedsize = stream.readInt();
    decodedSCPNomination.accepted = List<XdrValue>(acceptedsize);
    for (int i = 0; i < acceptedsize; i++) {
      decodedSCPNomination.accepted[i] = XdrValue.decode(stream);
    }
    return decodedSCPNomination;
  }
}

class XdrSCPQuorumSet {
  XdrSCPQuorumSet();
  XdrUint32 _threshold;
  XdrUint32 get threshold => this._threshold;
  set threshold(XdrUint32 value) => this._threshold = value;

  List<XdrPublicKey> _validators;
  List<XdrPublicKey> get validators => this._validators;
  set validators(List<XdrPublicKey> value) => this._validators = value;

  List<XdrSCPQuorumSet> _innerSets;
  List<XdrSCPQuorumSet> get innerSets => this._innerSets;
  set innerSets(List<XdrSCPQuorumSet> value) => this._innerSets = value;

  static void encode(
      XdrDataOutputStream stream, XdrSCPQuorumSet encodedSCPQuorumSet) {
    XdrUint32.encode(stream, encodedSCPQuorumSet._threshold);
    int validatorssize = encodedSCPQuorumSet.validators.length;
    stream.writeInt(validatorssize);
    for (int i = 0; i < validatorssize; i++) {
      XdrPublicKey.encode(stream, encodedSCPQuorumSet._validators[i]);
    }
    int innerSetssize = encodedSCPQuorumSet.innerSets.length;
    stream.writeInt(innerSetssize);
    for (int i = 0; i < innerSetssize; i++) {
      XdrSCPQuorumSet.encode(stream, encodedSCPQuorumSet._innerSets[i]);
    }
  }

  static XdrSCPQuorumSet decode(XdrDataInputStream stream) {
    XdrSCPQuorumSet decodedSCPQuorumSet = XdrSCPQuorumSet();
    decodedSCPQuorumSet._threshold = XdrUint32.decode(stream);
    int validatorssize = stream.readInt();
    decodedSCPQuorumSet._validators = List<XdrPublicKey>(validatorssize);
    for (int i = 0; i < validatorssize; i++) {
      decodedSCPQuorumSet._validators[i] = XdrPublicKey.decode(stream);
    }
    int innerSetssize = stream.readInt();
    decodedSCPQuorumSet._innerSets = List<XdrSCPQuorumSet>(innerSetssize);
    for (int i = 0; i < innerSetssize; i++) {
      decodedSCPQuorumSet._innerSets[i] = XdrSCPQuorumSet.decode(stream);
    }
    return decodedSCPQuorumSet;
  }
}

class XdrSCPStatement {
  XdrSCPStatement();
  XdrNodeID _nodeID;
  XdrNodeID get nodeID => this._nodeID;
  set nodeID(XdrNodeID value) => this._nodeID = value;

  XdrUint64 _slotIndex;
  XdrUint64 get slotIndex => this._slotIndex;
  set slotIndex(XdrUint64 value) => this._slotIndex = value;

  XdrSCPStatementPledges _pledges;
  XdrSCPStatementPledges get pledges => this._pledges;
  set pledges(XdrSCPStatementPledges value) => this._pledges = value;

  static void encode(
      XdrDataOutputStream stream, XdrSCPStatement encodedSCPStatement) {
    XdrNodeID.encode(stream, encodedSCPStatement.nodeID);
    XdrUint64.encode(stream, encodedSCPStatement.slotIndex);
    XdrSCPStatementPledges.encode(stream, encodedSCPStatement.pledges);
  }

  static XdrSCPStatement decode(XdrDataInputStream stream) {
    XdrSCPStatement decodedSCPStatement = XdrSCPStatement();
    decodedSCPStatement.nodeID = XdrNodeID.decode(stream);
    decodedSCPStatement.slotIndex = XdrUint64.decode(stream);
    decodedSCPStatement.pledges = XdrSCPStatementPledges.decode(stream);
    return decodedSCPStatement;
  }
}

class XdrSCPStatementPledges {
  XdrSCPStatementPledges();
  XdrSCPStatementType _type;
  XdrSCPStatementType get discriminant => this._type;
  set discriminant(XdrSCPStatementType value) => this._type = value;

  XdrSCPStatementPrepare _prepare;
  XdrSCPStatementPrepare get prepare => this._prepare;
  set prepare(XdrSCPStatementPrepare value) => this._prepare = value;

  XdrSCPStatementConfirm _confirm;
  XdrSCPStatementConfirm get confirm => this._confirm;
  set confirm(XdrSCPStatementConfirm value) => this._confirm = value;

  XdrSCPStatementExternalize _externalize;
  XdrSCPStatementExternalize get externalize => this._externalize;
  set externalize(XdrSCPStatementExternalize value) =>
      this._externalize = value;

  XdrSCPNomination _nominate;
  XdrSCPNomination get nominate => this._nominate;
  set nominate(XdrSCPNomination value) => this._nominate = value;

  static void encode(XdrDataOutputStream stream,
      XdrSCPStatementPledges encodedSCPStatementPledges) {
    stream.writeInt(encodedSCPStatementPledges.discriminant.value);
    switch (encodedSCPStatementPledges.discriminant) {
      case XdrSCPStatementType.SCP_ST_PREPARE:
        XdrSCPStatementPrepare.encode(
            stream, encodedSCPStatementPledges.prepare);
        break;
      case XdrSCPStatementType.SCP_ST_CONFIRM:
        XdrSCPStatementConfirm.encode(
            stream, encodedSCPStatementPledges.confirm);
        break;
      case XdrSCPStatementType.SCP_ST_EXTERNALIZE:
        XdrSCPStatementExternalize.encode(
            stream, encodedSCPStatementPledges.externalize);
        break;
      case XdrSCPStatementType.SCP_ST_NOMINATE:
        XdrSCPNomination.encode(stream, encodedSCPStatementPledges.nominate);
        break;
    }
  }

  static XdrSCPStatementPledges decode(XdrDataInputStream stream) {
    XdrSCPStatementPledges decodedSCPStatementPledges =
        XdrSCPStatementPledges();
    XdrSCPStatementType discriminant = XdrSCPStatementType.decode(stream);
    decodedSCPStatementPledges.discriminant = discriminant;
    switch (decodedSCPStatementPledges.discriminant) {
      case XdrSCPStatementType.SCP_ST_PREPARE:
        decodedSCPStatementPledges.prepare =
            XdrSCPStatementPrepare.decode(stream);
        break;
      case XdrSCPStatementType.SCP_ST_CONFIRM:
        decodedSCPStatementPledges.confirm =
            XdrSCPStatementConfirm.decode(stream);
        break;
      case XdrSCPStatementType.SCP_ST_EXTERNALIZE:
        decodedSCPStatementPledges.externalize =
            XdrSCPStatementExternalize.decode(stream);
        break;
      case XdrSCPStatementType.SCP_ST_NOMINATE:
        decodedSCPStatementPledges.nominate = XdrSCPNomination.decode(stream);
        break;
    }
    return decodedSCPStatementPledges;
  }
}

class XdrSCPStatementPrepare {
  XdrSCPStatementPrepare();
  XdrHash _quorumSetHash;
  XdrHash get quorumSetHash => this._quorumSetHash;
  set quorumSetHash(XdrHash value) => this._quorumSetHash = value;

  XdrSCPBallot _ballot;
  XdrSCPBallot get ballot => this._ballot;
  set ballot(XdrSCPBallot value) => this._ballot = value;

  XdrSCPBallot _prepared;
  XdrSCPBallot get prepared => this._prepared;
  set prepared(XdrSCPBallot value) => this._prepared = value;

  XdrSCPBallot _preparedPrime;
  XdrSCPBallot get preparedPrime => this._preparedPrime;
  set preparedPrime(XdrSCPBallot value) => this._preparedPrime = value;

  XdrUint32 _nC;
  XdrUint32 get nC => this._nC;
  set nC(XdrUint32 value) => this._nC = value;

  XdrUint32 _nH;
  XdrUint32 get nH => this._nH;
  set nH(XdrUint32 value) => this._nH = value;

  static void encode(XdrDataOutputStream stream,
      XdrSCPStatementPrepare encodedSCPStatementPrepare) {
    XdrHash.encode(stream, encodedSCPStatementPrepare._quorumSetHash);
    XdrSCPBallot.encode(stream, encodedSCPStatementPrepare.ballot);
    if (encodedSCPStatementPrepare.prepared != null) {
      stream.writeInt(1);
      XdrSCPBallot.encode(stream, encodedSCPStatementPrepare.prepared);
    } else {
      stream.writeInt(0);
    }
    if (encodedSCPStatementPrepare.preparedPrime != null) {
      stream.writeInt(1);
      XdrSCPBallot.encode(stream, encodedSCPStatementPrepare.preparedPrime);
    } else {
      stream.writeInt(0);
    }
    XdrUint32.encode(stream, encodedSCPStatementPrepare.nC);
    XdrUint32.encode(stream, encodedSCPStatementPrepare.nH);
  }

  static XdrSCPStatementPrepare decode(XdrDataInputStream stream) {
    XdrSCPStatementPrepare decodedSCPStatementPrepare =
        XdrSCPStatementPrepare();
    decodedSCPStatementPrepare.quorumSetHash = XdrHash.decode(stream);
    decodedSCPStatementPrepare.ballot = XdrSCPBallot.decode(stream);
    int preparedPresent = stream.readInt();
    if (preparedPresent != 0) {
      decodedSCPStatementPrepare.prepared = XdrSCPBallot.decode(stream);
    }
    int preparedPrimePresent = stream.readInt();
    if (preparedPrimePresent != 0) {
      decodedSCPStatementPrepare.preparedPrime = XdrSCPBallot.decode(stream);
    }
    decodedSCPStatementPrepare.nC = XdrUint32.decode(stream);
    decodedSCPStatementPrepare.nH = XdrUint32.decode(stream);
    return decodedSCPStatementPrepare;
  }
}

class XdrSCPStatementConfirm {
  XdrSCPStatementConfirm();
  XdrSCPBallot _ballot;
  XdrSCPBallot get ballot => this._ballot;
  set ballot(XdrSCPBallot value) => this._ballot = value;

  XdrUint32 _nPrepared;
  XdrUint32 get nPrepared => this._nPrepared;
  set nPrepared(XdrUint32 value) => this._nPrepared = value;

  XdrUint32 _nCommit;
  XdrUint32 get nCommit => this._nCommit;
  set nCommit(XdrUint32 value) => this._nCommit = value;

  XdrUint32 _nH;
  XdrUint32 get nH => this._nH;
  set nH(XdrUint32 value) => this._nH = value;

  XdrHash _quorumSetHash;
  XdrHash get quorumSetHash => this._quorumSetHash;
  set quorumSetHash(XdrHash value) => this._quorumSetHash = value;

  static void encode(XdrDataOutputStream stream,
      XdrSCPStatementConfirm encodedSCPStatementConfirm) {
    XdrSCPBallot.encode(stream, encodedSCPStatementConfirm.ballot);
    XdrUint32.encode(stream, encodedSCPStatementConfirm.nPrepared);
    XdrUint32.encode(stream, encodedSCPStatementConfirm.nCommit);
    XdrUint32.encode(stream, encodedSCPStatementConfirm.nH);
    XdrHash.encode(stream, encodedSCPStatementConfirm.quorumSetHash);
  }

  static XdrSCPStatementConfirm decode(XdrDataInputStream stream) {
    XdrSCPStatementConfirm decodedSCPStatementConfirm =
        XdrSCPStatementConfirm();
    decodedSCPStatementConfirm.ballot = XdrSCPBallot.decode(stream);
    decodedSCPStatementConfirm.nPrepared = XdrUint32.decode(stream);
    decodedSCPStatementConfirm.nCommit = XdrUint32.decode(stream);
    decodedSCPStatementConfirm.nH = XdrUint32.decode(stream);
    decodedSCPStatementConfirm.quorumSetHash = XdrHash.decode(stream);
    return decodedSCPStatementConfirm;
  }
}

class XdrSCPStatementExternalize {
  XdrSCPStatementExternalize();
  XdrSCPBallot _commit;
  XdrSCPBallot get commit => this._commit;
  set commit(XdrSCPBallot value) => this._commit = value;

  XdrUint32 _nH;
  XdrUint32 get nH => this._nH;
  set nH(XdrUint32 value) => this._nH = value;

  XdrHash _commitQuorumSetHash;
  XdrHash get commitQuorumSetHash => this._commitQuorumSetHash;
  set commitQuorumSetHash(XdrHash value) => this._commitQuorumSetHash = value;

  static void encode(XdrDataOutputStream stream,
      XdrSCPStatementExternalize encodedSCPStatementExternalize) {
    XdrSCPBallot.encode(stream, encodedSCPStatementExternalize.commit);
    XdrUint32.encode(stream, encodedSCPStatementExternalize.nH);
    XdrHash.encode(stream, encodedSCPStatementExternalize.commitQuorumSetHash);
  }

  static XdrSCPStatementExternalize decode(XdrDataInputStream stream) {
    XdrSCPStatementExternalize decodedSCPStatementExternalize =
        XdrSCPStatementExternalize();
    decodedSCPStatementExternalize.commit = XdrSCPBallot.decode(stream);
    decodedSCPStatementExternalize.nH = XdrUint32.decode(stream);
    decodedSCPStatementExternalize.commitQuorumSetHash = XdrHash.decode(stream);
    return decodedSCPStatementExternalize;
  }
}
