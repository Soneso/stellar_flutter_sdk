// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../claimable_balance_response.dart';

/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountSponsorshipCreatedEffectResponse extends EffectResponse {
  String sponsor;

  AccountSponsorshipCreatedEffectResponse(
      this.sponsor);

  factory AccountSponsorshipCreatedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new AccountSponsorshipCreatedEffectResponse(
          json['sponsor'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}

class AccountSponsorshipUpdatedEffectResponse extends EffectResponse {
  String newSponsor;
  String formerSponsor;

  AccountSponsorshipUpdatedEffectResponse(
      this.newSponsor, this.formerSponsor);

  factory AccountSponsorshipUpdatedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new AccountSponsorshipUpdatedEffectResponse(
          json['new_sponsor'] as String,
        json['former_sponsor'] as String,)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}

class AccountSponsorshipRemovedEffectResponse extends EffectResponse {
  String formerSponsor;

  AccountSponsorshipRemovedEffectResponse(
      this.formerSponsor);

  factory AccountSponsorshipRemovedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new AccountSponsorshipRemovedEffectResponse(
          json['former_sponsor'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}

class TrustlineSponsorshipCreatedEffectResponse extends EffectResponse {
  String sponsor;

  TrustlineSponsorshipCreatedEffectResponse(
      this.sponsor);

  factory TrustlineSponsorshipCreatedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new TrustlineSponsorshipCreatedEffectResponse(
          json['sponsor'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}

class TrustlineSponsorshipUpdatedEffectResponse extends EffectResponse {
  String newSponsor;
  String formerSponsor;

  TrustlineSponsorshipUpdatedEffectResponse(
      this.newSponsor, this.formerSponsor);

  factory TrustlineSponsorshipUpdatedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new TrustlineSponsorshipUpdatedEffectResponse(
        json['new_sponsor'] as String,
        json['former_sponsor'] as String,)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}

class TrustlineSponsorshipRemovedEffectResponse extends EffectResponse {
  String formerSponsor;

  TrustlineSponsorshipRemovedEffectResponse(
      this.formerSponsor);

  factory TrustlineSponsorshipRemovedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new TrustlineSponsorshipRemovedEffectResponse(
          json['former_sponsor'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}


class DataSponsorshipCreatedEffectResponse extends EffectResponse {
  String dataName;
  String sponsor;

  DataSponsorshipCreatedEffectResponse(this.dataName,
      this.sponsor);

  factory DataSponsorshipCreatedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new DataSponsorshipCreatedEffectResponse(
          json['data_name'] as String,
          json['sponsor'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}

class DataSponsorshipUpdatedEffectResponse extends EffectResponse {
  String dataName;
  String newSponsor;
  String formerSponsor;

  DataSponsorshipUpdatedEffectResponse(this.dataName,
      this.newSponsor, this.formerSponsor);

  factory DataSponsorshipUpdatedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new DataSponsorshipUpdatedEffectResponse(
        json['data_name'] as String,
        json['new_sponsor'] as String,
        json['former_sponsor'] as String,)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}

class DataSponsorshipRemovedEffectResponse extends EffectResponse {
  String dataName;
  String formerSponsor;

  DataSponsorshipRemovedEffectResponse(this.dataName,
      this.formerSponsor);

  factory DataSponsorshipRemovedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new DataSponsorshipRemovedEffectResponse(
          json['data_name'] as String,
          json['former_sponsor'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}


class ClaimableBalanceSponsorshipCreatedEffectResponse extends EffectResponse {
  String sponsor;

  ClaimableBalanceSponsorshipCreatedEffectResponse(
      this.sponsor);

  factory ClaimableBalanceSponsorshipCreatedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new ClaimableBalanceSponsorshipCreatedEffectResponse(
          json['sponsor'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}

class ClaimableBalanceSponsorshipUpdatedEffectResponse extends EffectResponse {
  String newSponsor;
  String formerSponsor;

  ClaimableBalanceSponsorshipUpdatedEffectResponse(
      this.newSponsor, this.formerSponsor);

  factory ClaimableBalanceSponsorshipUpdatedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new ClaimableBalanceSponsorshipUpdatedEffectResponse(
        json['new_sponsor'] as String,
        json['former_sponsor'] as String,)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}

class ClaimableBalanceSponsorshipRemovedEffectResponse extends EffectResponse {
  String formerSponsor;

  ClaimableBalanceSponsorshipRemovedEffectResponse(
      this.formerSponsor);

  factory ClaimableBalanceSponsorshipRemovedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new ClaimableBalanceSponsorshipRemovedEffectResponse(
          json['former_sponsor'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}


class SignerSponsorshipCreatedEffectResponse extends EffectResponse {
  String signer;
  String sponsor;

  SignerSponsorshipCreatedEffectResponse(this.signer,
      this.sponsor);

  factory SignerSponsorshipCreatedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new SignerSponsorshipCreatedEffectResponse(
          json['signer'] as String,
          json['sponsor'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}

class SignerSponsorshipUpdatedEffectResponse extends EffectResponse {
  String signer;
  String newSponsor;
  String formerSponsor;

  SignerSponsorshipUpdatedEffectResponse(this.signer,
      this.newSponsor, this.formerSponsor);

  factory SignerSponsorshipUpdatedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new SignerSponsorshipUpdatedEffectResponse(
        json['signer'] as String,
        json['new_sponsor'] as String,
        json['former_sponsor'] as String,)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}

class SignerSponsorshipRemovedEffectResponse extends EffectResponse {
  String signer;
  String formerSponsor;

  SignerSponsorshipRemovedEffectResponse(this.signer,
      this.formerSponsor);

  factory SignerSponsorshipRemovedEffectResponse.fromJson(
      Map<String, dynamic> json) =>
      new SignerSponsorshipRemovedEffectResponse(
          json['signer'] as String,
          json['former_sponsor'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}