import 'response.dart';

/// Represents a challenge response.
class ChallengeResponse extends Response {
  String transaction;

  ChallengeResponse(this.transaction);

  factory ChallengeResponse.fromJson(Map<String, dynamic> json) {
    return new ChallengeResponse(
        json['transaction'] == null ? null : json['transaction'] as String);
  }
}

class SubmitCompletedChallengeResponse extends Response {
  String jwtToken;
  String error;

  SubmitCompletedChallengeResponse(this.jwtToken, this.error);

  factory SubmitCompletedChallengeResponse.fromJson(
          Map<String, dynamic> json) =>
      new SubmitCompletedChallengeResponse(
          json['token'] == null ? null : json['token'] as String,
          json['error'] == null ? null : json['error'] as String);
}
