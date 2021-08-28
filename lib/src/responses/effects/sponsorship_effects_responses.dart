// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../response.dart';

/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountSponsorshipCreatedEffectResponse extends EffectResponse {
  String? sponsor;

  AccountSponsorshipCreatedEffectResponse(this.sponsor);

  factory AccountSponsorshipCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountSponsorshipCreatedEffectResponse(json['sponsor'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class AccountSponsorshipUpdatedEffectResponse extends EffectResponse {
  String? newSponsor;
  String? formerSponsor;

  AccountSponsorshipUpdatedEffectResponse(this.newSponsor, this.formerSponsor);

  factory AccountSponsorshipUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountSponsorshipUpdatedEffectResponse(
        json['new_sponsor'],
        json['former_sponsor'],
      )
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class AccountSponsorshipRemovedEffectResponse extends EffectResponse {
  String? formerSponsor;

  AccountSponsorshipRemovedEffectResponse(this.formerSponsor);

  factory AccountSponsorshipRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountSponsorshipRemovedEffectResponse(json['former_sponsor'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class TrustlineSponsorshipCreatedEffectResponse extends EffectResponse {
  String? sponsor;

  TrustlineSponsorshipCreatedEffectResponse(this.sponsor);

  factory TrustlineSponsorshipCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      TrustlineSponsorshipCreatedEffectResponse(json['sponsor'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class TrustlineSponsorshipUpdatedEffectResponse extends EffectResponse {
  String? newSponsor;
  String? formerSponsor;

  TrustlineSponsorshipUpdatedEffectResponse(this.newSponsor, this.formerSponsor);

  factory TrustlineSponsorshipUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      TrustlineSponsorshipUpdatedEffectResponse(
        json['new_sponsor'],
        json['former_sponsor'],
      )
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class TrustlineSponsorshipRemovedEffectResponse extends EffectResponse {
  String? formerSponsor;

  TrustlineSponsorshipRemovedEffectResponse(this.formerSponsor);

  factory TrustlineSponsorshipRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      TrustlineSponsorshipRemovedEffectResponse(json['former_sponsor'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class DataSponsorshipCreatedEffectResponse extends EffectResponse {
  String? dataName;
  String? sponsor;

  DataSponsorshipCreatedEffectResponse(this.dataName, this.sponsor);

  factory DataSponsorshipCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      DataSponsorshipCreatedEffectResponse(json['data_name'], json['sponsor'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class DataSponsorshipUpdatedEffectResponse extends EffectResponse {
  String? dataName;
  String? newSponsor;
  String? formerSponsor;

  DataSponsorshipUpdatedEffectResponse(this.dataName, this.newSponsor, this.formerSponsor);

  factory DataSponsorshipUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      DataSponsorshipUpdatedEffectResponse(
        json['data_name'],
        json['new_sponsor'],
        json['former_sponsor'],
      )
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class DataSponsorshipRemovedEffectResponse extends EffectResponse {
  String? dataName;
  String? formerSponsor;

  DataSponsorshipRemovedEffectResponse(this.dataName, this.formerSponsor);

  factory DataSponsorshipRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      DataSponsorshipRemovedEffectResponse(json['data_name'], json['former_sponsor'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class ClaimableBalanceSponsorshipCreatedEffectResponse extends EffectResponse {
  String? sponsor;

  ClaimableBalanceSponsorshipCreatedEffectResponse(this.sponsor);

  factory ClaimableBalanceSponsorshipCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      ClaimableBalanceSponsorshipCreatedEffectResponse(json['sponsor'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class ClaimableBalanceSponsorshipUpdatedEffectResponse extends EffectResponse {
  String? newSponsor;
  String? formerSponsor;

  ClaimableBalanceSponsorshipUpdatedEffectResponse(this.newSponsor, this.formerSponsor);

  factory ClaimableBalanceSponsorshipUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      ClaimableBalanceSponsorshipUpdatedEffectResponse(
        json['new_sponsor'],
        json['former_sponsor'],
      )
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class ClaimableBalanceSponsorshipRemovedEffectResponse extends EffectResponse {
  String? formerSponsor;

  ClaimableBalanceSponsorshipRemovedEffectResponse(this.formerSponsor);

  factory ClaimableBalanceSponsorshipRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      ClaimableBalanceSponsorshipRemovedEffectResponse(json['former_sponsor'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class SignerSponsorshipCreatedEffectResponse extends EffectResponse {
  String? signer;
  String? sponsor;

  SignerSponsorshipCreatedEffectResponse(this.signer, this.sponsor);

  factory SignerSponsorshipCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      SignerSponsorshipCreatedEffectResponse(json['signer'], json['sponsor'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class SignerSponsorshipUpdatedEffectResponse extends EffectResponse {
  String? signer;
  String? newSponsor;
  String? formerSponsor;

  SignerSponsorshipUpdatedEffectResponse(this.signer, this.newSponsor, this.formerSponsor);

  factory SignerSponsorshipUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      SignerSponsorshipUpdatedEffectResponse(
        json['signer'],
        json['new_sponsor'],
        json['former_sponsor'],
      )
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class SignerSponsorshipRemovedEffectResponse extends EffectResponse {
  String? signer;
  String? formerSponsor;

  SignerSponsorshipRemovedEffectResponse(this.signer, this.formerSponsor);

  factory SignerSponsorshipRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      SignerSponsorshipRemovedEffectResponse(json['signer'], json['former_sponsor'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}
