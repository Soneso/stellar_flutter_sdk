import 'response.dart';

/// Represents a challenge transaction for SEP-10 Web Authentication.
///
/// This response contains a challenge transaction issued by a web authentication
/// server implementing SEP-10 protocol version 3.4.1. The challenge is an XDR-encoded
/// transaction that the client must sign with their account's secret key to prove
/// ownership of the account.
///
/// The SEP-10 authentication flow consists of three steps:
/// 1. Client requests a challenge from the server
/// 2. Client receives this ChallengeResponse with the challenge transaction
/// 3. Client signs the transaction and submits it back to the server
/// 4. Server validates the signature and returns a JWT token
///
/// The challenge transaction typically has a short validity window (usually
/// 5-15 minutes) and includes:
/// - A ManageData operation with random data as the challenge
/// - The client's account as the source
/// - The server's signing key as a signer
/// - A time-bound to limit validity
///
/// The optional [networkPassphrase] field (recommended in SEP-10 v3.4.1) allows
/// clients to verify they are using the correct network passphrase for signing,
/// helping to identify configuration errors.
///
/// Example:
/// ```dart
/// // Request a challenge from the web auth server
/// var webAuth = WebAuth(webAuthEndpoint, network, serverSigningKey, homeDomain);
/// var challenge = await webAuth.getChallengeResponse(clientAccountId);
///
/// // Verify network passphrase if provided (recommended)
/// if (challenge.networkPassphrase != null &&
///     challenge.networkPassphrase != network.networkPassphrase) {
///   throw Exception('Network mismatch detected');
/// }
///
/// // Extract the transaction XDR
/// String transactionXdr = challenge.transaction!;
///
/// // Parse and sign the transaction
/// var transaction = AbstractTransaction.fromEnvelopeXdrString(transactionXdr);
/// transaction.sign(clientKeyPair, network);
///
/// // Submit the signed transaction back to the server
/// var signedXdr = transaction.toEnvelopeXdrBase64();
/// var authResponse = await webAuth.sendSignedChallengeTransaction(signedXdr);
/// ```
///
/// See also:
/// - [SubmitCompletedChallengeResponse] for the authentication response
/// - [SEP-10 Web Authentication](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md) specification
/// - [WebAuth] class for simplified SEP-10 implementation
class ChallengeResponse extends Response {
  /// XDR-encoded challenge transaction that must be signed by the client.
  ///
  /// This is a base64-encoded transaction envelope in XDR format. The client
  /// must decode this, sign it with their account's secret key, and submit
  /// the signed transaction back to the server for authentication.
  String? transaction;

  /// Stellar network passphrase used by the server (optional but recommended).
  ///
  /// This field allows clients to verify they are using the correct network
  /// passphrase when signing the transaction. Common values:
  /// - "Public Global Stellar Network ; September 2015" (mainnet/pubnet)
  /// - "Test SDF Network ; September 2015" (testnet)
  ///
  /// If present, clients should verify this matches their expected network
  /// before signing to avoid configuration errors where a client configured
  /// for testnet accidentally connects to a mainnet server or vice versa.
  ///
  /// Example verification:
  /// ```dart
  /// if (challenge.networkPassphrase != null &&
  ///     challenge.networkPassphrase != Network.PUBLIC.networkPassphrase) {
  ///   throw Exception('Network mismatch: expected PUBLIC, got ${challenge.networkPassphrase}');
  /// }
  /// ```
  String? networkPassphrase;

  ChallengeResponse(this.transaction, {this.networkPassphrase});

  factory ChallengeResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeResponse(
      json['transaction'] == null ? null : json['transaction'],
      networkPassphrase: json['network_passphrase'] == null ? null : json['network_passphrase'],
    );
  }
}

/// Represents the response after submitting a signed SEP-10 challenge transaction.
///
/// After successfully signing and submitting a challenge transaction, the web
/// authentication server validates the signature and returns this response
/// containing a JWT token. This token can be used to authenticate subsequent
/// API requests to protected endpoints.
///
/// The JWT token typically includes:
/// - The authenticated account ID
/// - Token expiration time
/// - Issuer information
/// - Optional memo for muxed accounts
///
/// If authentication fails (invalid signature, expired challenge, etc.), the
/// [error] field will contain an error message explaining the failure.
///
/// Example:
/// ```dart
/// // Sign and submit the challenge
/// var webAuth = WebAuth(webAuthEndpoint, network, serverSigningKey);
/// var challenge = await webAuth.getChallenge(clientAccountId);
///
/// var transaction = AbstractTransaction.fromEnvelopeXdrString(challenge.transaction!);
/// transaction.sign(clientKeyPair, network);
///
/// var response = await webAuth.submitSignedChallenge(
///   transaction.toEnvelopeXdrBase64()
/// );
///
/// if (response.jwtToken != null) {
///   // Authentication successful, use the token
///   String authToken = response.jwtToken!;
///
///   // Use the token in API requests
///   var headers = {
///     'Authorization': 'Bearer $authToken',
///   };
///
///   // Make authenticated requests to protected endpoints
///   var protectedData = await http.get(
///     Uri.parse('https://example.com/api/protected'),
///     headers: headers,
///   );
/// } else {
///   // Authentication failed
///   print('Error: ${response.error}');
/// }
/// ```
///
/// See also:
/// - [ChallengeResponse] for the initial challenge request
/// - [SEP-10 Web Authentication](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md) specification
/// - [WebAuth] class for simplified SEP-10 implementation
class SubmitCompletedChallengeResponse extends Response {
  /// JWT token for authenticating subsequent API requests.
  ///
  /// This token should be included in the Authorization header of requests
  /// to protected endpoints as: `Authorization: Bearer {token}`
  ///
  /// The token has an expiration time (typically 24 hours) and must be
  /// refreshed by requesting a new challenge when it expires.
  String? jwtToken;

  /// Error message if authentication failed.
  ///
  /// If present, indicates that the challenge submission was rejected.
  /// Common error reasons include:
  /// - Invalid signature
  /// - Expired challenge transaction
  /// - Challenge transaction was modified
  /// - Invalid account or missing authorization
  String? error;

  SubmitCompletedChallengeResponse(this.jwtToken, this.error);

  factory SubmitCompletedChallengeResponse.fromJson(Map<String, dynamic> json) =>
      SubmitCompletedChallengeResponse(json['token'] == null ? null : json['token'],
          json['error'] == null ? null : json['error']);
}
