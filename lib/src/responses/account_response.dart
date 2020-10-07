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
  int _sequenceNumber;
  String pagingToken;
  int subentryCount;
  String inflationDestination;
  String homeDomain;
  int lastModifiedLedger;
  Thresholds thresholds;
  Flags flags;
  List<Balance> balances;
  List<Signer> signers;
  AccountResponseData data;
  AccountResponseLinks links;
  String sponsor;
  int numSponsoring;
  int numSponsored;
  int muxedAccountMed25519Id; // ID to be used if this account is used as MuxedAccountMed25519

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

  @override
  KeyPair get keypair => KeyPair.fromAccountId(accountId);

  @override
  int get sequenceNumber => _sequenceNumber;

  @override
  int get incrementedSequenceNumber => _sequenceNumber + 1;

  @override
  void incrementSequenceNumber() => _sequenceNumber++;

  @override
  MuxedAccount get muxedAccount =>
      MuxedAccount(accountId, muxedAccountMed25519Id);

  factory AccountResponse.fromJson(Map<String, dynamic> json) =>
      new AccountResponse(
        json['account_id'] as String,
        convertInt(json['sequence']),
        json['paging_token'] as String,
        convertInt(json['subentry_count']),
        json['inflation_destination'] as String,
        json['home_domain'] as String,
        convertInt(json['last_modified_ledger']),
        json['thresholds'] == null
            ? null
            : new Thresholds.fromJson(
                json['thresholds'] as Map<String, dynamic>),
        json['flags'] == null
            ? null
            : new Flags.fromJson(json['flags'] as Map<String, dynamic>),
        (json['balances'] as List)
            ?.map((e) => e == null
                ? null
                : new Balance.fromJson(e as Map<String, dynamic>))
            ?.toList(),
        (json['signers'] as List)
            ?.map((e) => e == null
                ? null
                : new Signer.fromJson(e as Map<String, dynamic>))
            ?.toList(),
        json['data'] == null
            ? null
            : new AccountResponseData(json['data'] as Map<String, dynamic>),
        json['_links'] == null
            ? null
            : new AccountResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>),
        json['sponsor'] as String,
        convertInt(json['num_sponsoring']),
        convertInt(json['num_sponsored']),
      );
}

/// Represents account thresholds from the horizon account response.
class Thresholds {
  int lowThreshold;
  int medThreshold;
  int highThreshold;

  Thresholds(this.lowThreshold, this.medThreshold, this.highThreshold);

  factory Thresholds.fromJson(Map<String, dynamic> json) => new Thresholds(
      convertInt(json['low_threshold']),
      convertInt(json['med_threshold']),
      convertInt(json['high_threshold']));
}

/// Represents account flags from the horizon account response.
class Flags {
  bool authRequired;
  bool authRevocable;
  bool authImmutable;

  Flags(this.authRequired, this.authRevocable, this.authImmutable);

  factory Flags.fromJson(Map<String, dynamic> json) => new Flags(
      json['auth_required'] as bool,
      json['auth_revocable'] as bool,
      json['auth_immutable'] as bool);
}

/// Represents account balance from the horizon account response.
class Balance {
  String assetType;
  String assetCode;
  String assetIssuer;
  String limit;
  String balance;
  String buyingLiabilities;
  String sellingLiabilities;
  bool isAuthorized;
  bool isAuthorizedToMaintainLiabilities;
  int lastModifiedLedger;
  String sponsor;

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
      this.lastModifiedLedger,
      this.sponsor);

  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode, assetIssuer);
    }
  }

  factory Balance.fromJson(Map<String, dynamic> json) => new Balance(
      json['asset_type'] as String,
      json['asset_code'] as String,
      json['asset_issuer'] as String,
      json['balance'] as String,
      json['limit'] as String,
      json['buying_liabilities'] as String,
      json['selling_liabilities'] as String,
      json['is_authorized'] as bool,
      json['is_authorized_to_maintain_liabilities'] as bool,
      convertInt(json['last_modified_ledger']),
      json['sponsor'] as String);
}

/// Represents account signers from the horizon account response.
class Signer {
  String key;
  String type;
  int weight;
  String sponsor;

  Signer(this.key, this.type, this.weight, this.sponsor);

  String get accountId => key;

  factory Signer.fromJson(Map<String, dynamic> json) => new Signer(
      json['key'] as String,
      json['type'] as String,
      convertInt(json['weight']),
      json['sponsor'] as String);
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
  Link effects;
  Link offers;
  Link operations;
  Link self;
  Link transactions;

  AccountResponseLinks(
      this.effects, this.offers, this.operations, this.self, this.transactions);

  factory AccountResponseLinks.fromJson(Map<String, dynamic> json) {
    return new AccountResponseLinks(
        json['effects'] == null
            ? null
            : new Link.fromJson(json['effects'] as Map<String, dynamic>),
        json['offers'] == null
            ? null
            : new Link.fromJson(json['offers'] as Map<String, dynamic>),
        json['operations'] == null
            ? null
            : new Link.fromJson(json['operations'] as Map<String, dynamic>),
        json['self'] == null
            ? null
            : new Link.fromJson(json['self'] as Map<String, dynamic>),
        json['transactions'] == null
            ? null
            : new Link.fromJson(json['transactions'] as Map<String, dynamic>));
  }
}
