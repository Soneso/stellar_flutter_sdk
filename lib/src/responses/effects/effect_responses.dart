// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../response.dart';
import 'account_effects_responses.dart';
import 'signer_effects_responses.dart';
import 'trustline_effects_responses.dart';
import 'trade_effects_responses.dart';
import 'data_effects_responses.dart';
import 'misc_effects_responses.dart';
import 'claimable_balances_effects.dart';
import 'sponsorship_effects_responses.dart';
import 'liquidity_pools_efffects_responses.dart';

///Abstract class for effect responses.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
abstract class EffectResponse extends Response {
  String? id;
  String? account;
  String? accountMuxed;
  String? accountMuxedId;
  String? type;
  String? createdAt;
  String? pagingToken;
  EffectResponseLinks? links;

  EffectResponse();

  factory EffectResponse.fromJson(Map<String, dynamic> json) {
    int? type = convertInt(json["type_i"]);
    switch (type) {
      // Account effects
      case 0:
        return AccountCreatedEffectResponse.fromJson(json);
      case 1:
        return AccountRemovedEffectResponse.fromJson(json);
      case 2:
        return AccountCreditedEffectResponse.fromJson(json);
      case 3:
        return AccountDebitedEffectResponse.fromJson(json);
      case 4:
        return AccountThresholdsUpdatedEffectResponse.fromJson(json);
      case 5:
        return AccountHomeDomainUpdatedEffectResponse.fromJson(json);
      case 6:
        return AccountFlagsUpdatedEffectResponse.fromJson(json);
      case 7:
        return AccountInflationDestinationUpdatedEffectResponse.fromJson(json);
      // Signer effects
      case 10:
        return SignerCreatedEffectResponse.fromJson(json);
      case 11:
        return SignerRemovedEffectResponse.fromJson(json);
      case 12:
        return SignerUpdatedEffectResponse.fromJson(json);
      // Trustline effects
      case 20:
        return TrustlineCreatedEffectResponse.fromJson(json);
      case 21:
        return TrustlineRemovedEffectResponse.fromJson(json);
      case 22:
        return TrustlineUpdatedEffectResponse.fromJson(json);
      case 23:
        return TrustlineAuthorizedEffectResponse.fromJson(json);
      case 24:
        return TrustlineDeauthorizedEffectResponse.fromJson(json);
      case 25:
        return TrustlineAuthorizedToMaintainLiabilitiesEffectResponse.fromJson(json);
      case 26:
        return TrustLineFlagsUpdatedEffectResponse.fromJson(json);
      // Trading effects
      case 30:
        return OfferCreatedEffectResponse.fromJson(json);
      case 31:
        return OfferRemovedEffectResponse.fromJson(json);
      case 32:
        return OfferUpdatedEffectResponse.fromJson(json);
      case 33:
        return TradeEffectResponse.fromJson(json);
      // Data effects
      case 40:
        return DataCreatedEffectResponse.fromJson(json);
      case 41:
        return DataRemovedEffectResponse.fromJson(json);
      case 42:
        return DataUpdatedEffectResponse.fromJson(json);
      // Bump Sequence effects
      case 43:
        return SequenceBumpedEffectResponse.fromJson(json);
      // Claimable Balance effects
      case 50:
        return ClaimableBalanceCreatedEffectResponse.fromJson(json);
      case 51:
        return ClaimableBalanceClaimantCreatedEffectResponse.fromJson(json);
      case 52:
        return ClaimableBalanceClaimedEffectResponse.fromJson(json);
      // Sponsorship
      case 60:
        return AccountSponsorshipCreatedEffectResponse.fromJson(json);
      case 61:
        return AccountSponsorshipUpdatedEffectResponse.fromJson(json);
      case 62:
        return AccountSponsorshipRemovedEffectResponse.fromJson(json);
      case 63:
        return TrustlineSponsorshipCreatedEffectResponse.fromJson(json);
      case 64:
        return TrustlineSponsorshipUpdatedEffectResponse.fromJson(json);
      case 65:
        return TrustlineSponsorshipRemovedEffectResponse.fromJson(json);
      case 66:
        return DataSponsorshipCreatedEffectResponse.fromJson(json);
      case 67:
        return DataSponsorshipUpdatedEffectResponse.fromJson(json);
      case 68:
        return DataSponsorshipRemovedEffectResponse.fromJson(json);
      case 69:
        return ClaimableBalanceSponsorshipCreatedEffectResponse.fromJson(json);
      case 70:
        return ClaimableBalanceSponsorshipUpdatedEffectResponse.fromJson(json);
      case 71:
        return ClaimableBalanceSponsorshipRemovedEffectResponse.fromJson(json);
      case 72:
        return SignerSponsorshipCreatedEffectResponse.fromJson(json);
      case 73:
        return SignerSponsorshipUpdatedEffectResponse.fromJson(json);
      case 74:
        return SignerSponsorshipRemovedEffectResponse.fromJson(json);
      case 80:
        return ClaimableBalanceClawedBackEffectResponse.fromJson(json);
      case 90:
        return LiquidityPoolDepositedEffectResponse.fromJson(json);
      case 91:
        return LiquidityPoolWithdrewEffectResponse.fromJson(json);
      case 92:
        return LiquidityPoolTradeEffectResponse.fromJson(json);
      case 93:
        return LiquidityPoolCreatedEffectResponse.fromJson(json);
      case 94:
        return LiquidityPoolRemovedEffectResponse.fromJson(json);
      case 95:
        return LiquidityPoolRevokedEffectResponse.fromJson(json);
      default:
        throw Exception("Invalid operation type");
    }
  }
}

///Represents effect links.
class EffectResponseLinks {
  Link? operation;
  Link? precedes;
  Link? succeeds;

  EffectResponseLinks(this.operation, this.precedes, this.succeeds);

  factory EffectResponseLinks.fromJson(Map<String, dynamic> json) {
    return EffectResponseLinks(
        json['operation'] == null ? null : Link.fromJson(json['operation']),
        json['precedes'] == null ? null : Link.fromJson(json['precedes']),
        json['succeeds'] == null ? null : Link.fromJson(json['succeeds']));
  }

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'operation': operation, 'precedes': precedes, 'succeeds': succeeds};
}
