import 'response.dart';

/// Represents a challenge response.
class ChallengeResponse extends Response {
  String? transaction;

  ChallengeResponse(this.transaction);

  factory ChallengeResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeResponse(json['transaction'] == null ? null : json['transaction']);
  }
}

class SubmitCompletedChallengeResponse extends Response {
  String? jwtToken;
  String? error;

  SubmitCompletedChallengeResponse(this.jwtToken, this.error);

  factory SubmitCompletedChallengeResponse.fromJson(Map<String, dynamic> json) =>
      SubmitCompletedChallengeResponse(json['token'] == null ? null : json['token'],
          json['error'] == null ? null : json['error']);
}
