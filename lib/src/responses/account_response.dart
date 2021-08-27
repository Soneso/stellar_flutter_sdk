// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import '../assets.dart';
import '../asset_type_native.dart';
import '../key_pair.dart';
import '../account.dart';
import '../muxed_account.dart';
import 'response.dart';

/// Represents an account response received from horizon. Users interact with the Stellar network through accounts. Everything else in the ledger—assets, offers, trustlines, etc.—are owned by accounts, and accounts must authorize all changes to the ledger through signed transactions.
/// See: <a href="https://developers.stellar.org/api/resources/accounts/" target="_blank">Account documentation</a>.
class AccountResponse extends Response implements TransactionBuilderAccount {
  String accountId;
  int? _sequenceNumber;
  String pagingToken;
  int? subentryCount;
  String? inflationDestination;
  String? homeDomain;
  int? lastModifiedLedger;
  Thresholds? thresholds;
  Flags? flags;
  // List<Balance?>? balances;
  // List<Signer?>? signers;
  List<dynamic>? balances;
  List<dynamic>? signers;
  AccountResponseData? data;
  AccountResponseLinks? links;
  String? sponsor;
  int? numSponsoring;
  int? numSponsored;
  int? muxedAccountMed25519Id; // ID to be used if this account is used as MuxedAccountMed25519

  AccountResponse(
      this.accountId,
      this._sequenceNumber,
      this.pagingToken,
      this.subentryCount,
      this.inflationDestination,
      this.homeDomain,
      this.lastModifiedLedger,
      this.thresholds,
      this.flags,
      this.balances,
      this.signers,
      this.data,
      this.links,
      this.sponsor,
      this.numSponsored,
      this.numSponsoring);

  // @override
  KeyPair get keypair => KeyPair.fromAccountId(accountId);

  @override
  int get sequenceNumber => _sequenceNumber!;

  @override
  int get incrementedSequenceNumber => _sequenceNumber! + 1;

  @override
  void incrementSequenceNumber() =>
      _sequenceNumber == null ? null : _sequenceNumber = _sequenceNumber! + 1;

  @override
  MuxedAccount get muxedAccount => MuxedAccount(accountId, muxedAccountMed25519Id);

  factory AccountResponse.fromJson(Map<String, dynamic> json) => AccountResponse(
        json['account_id'],
        convertInt(json['sequence']),
        json['paging_token'],
        convertInt(json['subentry_count']),
        json['inflation_destination'],
        json['home_domain'],
        convertInt(json['last_modified_ledger']),
        json['thresholds'] == null ? null : Thresholds.fromJson(json['thresholds']),
        json['flags'] == null ? null : Flags.fromJson(json['flags']),
        (json['balances']).map((e) => e == null ? null : Balance.fromJson(e)).toList(),
        (json['signers']).map((e) => e == null ? null : Signer.fromJson(e)).toList(),
        json['data'] == null ? null : AccountResponseData(json['data']),
        json['_links'] == null ? null : AccountResponseLinks.fromJson(json['_links']),
        json['sponsor'],
        convertInt(json['num_sponsoring']),
        convertInt(json['num_sponsored']),
      );
}

/// Represents account thresholds from the horizon account response.
class Thresholds {
  int? lowThreshold;
  int? medThreshold;
  int? highThreshold;

  Thresholds(this.lowThreshold, this.medThreshold, this.highThreshold);

  factory Thresholds.fromJson(Map<String, dynamic> json) => Thresholds(
      convertInt(json['low_threshold']),
      convertInt(json['med_threshold']),
      convertInt(json['high_threshold']));
}

/// Represents account flags from the horizon account response.
class Flags {
  bool? authRequired;
  bool? authRevocable;
  bool? authImmutable;
  bool? clawbackEnabled;

  Flags(this.authRequired, this.authRevocable, this.authImmutable, this.clawbackEnabled);

  factory Flags.fromJson(Map<String, dynamic> json) => Flags(
        json['auth_required'],
        json['auth_revocable'],
        json['auth_immutable'],
        json['auth_clawback_enabled'],
      );
}

/// Represents account balance from the horizon account response.
class Balance {
  String? assetType;
  String? assetCode;
  String? assetIssuer;
  String? limit;
  String? balance;
  String? buyingLiabilities;
  String? sellingLiabilities;
  bool? isAuthorized;
  bool? isAuthorizedToMaintainLiabilities;
  bool? isClawbackEnabled;
  int? lastModifiedLedger;
  String? sponsor;

  Balance(
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.balance,
      this.limit,
      this.buyingLiabilities,
      this.sellingLiabilities,
      this.isAuthorized,
      this.isAuthorizedToMaintainLiabilities,
      this.isClawbackEnabled,
      this.lastModifiedLedger,
      this.sponsor);

  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode!, assetIssuer!);
    }
  }

  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
      json['asset_type'],
      json['asset_code'],
      json['asset_issuer'],
      json['balance'],
      json['limit'],
      json['buying_liabilities'],
      json['selling_liabilities'],
      json['is_authorized'],
      json['is_authorized_to_maintain_liabilities'],
      json['is_clawback_enabled'] == null ? null : json['is_clawback_enabled'],
      convertInt(json['last_modified_ledger']),
      json['sponsor']);
}

/// Represents account signers from the horizon account response.
class Signer {
  String? key;
  String? type;
  int? weight;
  String? sponsor;

  Signer(this.key, this.type, this.weight, this.sponsor);

  String? get accountId => key;

  factory Signer.fromJson(Map<String, dynamic> json) =>
      Signer(json['key'], json['type'], convertInt(json['weight']), json['sponsor']);
}

/// Data connected to account from the horizon account response.
class AccountResponseData {
  Map<String, dynamic> _map = {};

  AccountResponseData(this._map);

  int get length => _map.length;

  Iterable<String> get keys => _map.keys;

  /// Gets base64-encoded value for a given [key].
  String operator [](Object key) => _map[key] as String;

  /// Gets raw value for a given [key].
  Uint8List getDecoded(String key) => base64Decode(this[key]);
}

/// Links from the account response.
class AccountResponseLinks {
  Link? effects;
  Link? offers;
  Link? operations;
  Link? self;
  Link? transactions;

  AccountResponseLinks(this.effects, this.offers, this.operations, this.self, this.transactions);

  factory AccountResponseLinks.fromJson(Map<String, dynamic> json) {
    return AccountResponseLinks(
        json['effects'] == null ? null : Link.fromJson(json['effects']),
        json['offers'] == null ? null : Link.fromJson(json['offers']),
        json['operations'] == null ? null : Link.fromJson(json['operations']),
        json['self'] == null ? null : Link.fromJson(json['self']),
        json['transactions'] == null ? null : Link.fromJson(json['transactions']));
  }
}
