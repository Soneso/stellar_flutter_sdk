// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../0001/stellar_toml.dart';
import '../../transaction.dart';
import '../../key_pair.dart';
import '../../network.dart';
import '../../util.dart';
import '../../responses/response.dart';
import '../../responses/challenge_response.dart';
import '../../requests/request_builder.dart';
import '../../xdr/xdr_transaction.dart';
import '../../xdr/xdr_operation.dart';
import '../../xdr/xdr_type.dart';
import '../../xdr/xdr_signing.dart';

class WebAuth {
  String _authEndpoint;
  String _serverSigningKey;
  Network _network;
  String _serverHomeDomain;
  http.Client httpClient = new http.Client();

  /// Constructor
  /// - Parameter authEndpoint: Endpoint to be used for the authentication procedure. Usually taken from stellar.toml.
  /// - Parameter network: The network used.
  /// - Parameter serverSigningKey: The server public key, taken from stellar.toml.
  /// - Parameter serverHomeDomain: The server home domain of the server where the stellar.toml was loaded from
  WebAuth(String authEndpoint, Network network, String serverSigningKey,
      String serverHomeDomain) {
    _authEndpoint = checkNotNull(authEndpoint, "authEndpoint cannot be null");
    _network = checkNotNull(network, "network cannot be null");
    _serverSigningKey =
        checkNotNull(serverSigningKey, "serverSigningKey cannot be null");
    _serverHomeDomain =
        checkNotNull(serverHomeDomain, "serverHomeDomain cannot be null");
  }

  /// Creates a WebAuth instance by loading the needed data from the stellar.toml file hosted on the given domain.
  /// e.g. fromDomain("soneso.com", Network.TESTNET)
  /// - Parameter domain: The domain from which to get the stellar information
  /// - Parameter network: The network used.
  static Future<WebAuth> fromDomain(String domain, Network network) async {
    String vDomain = checkNotNull(domain, "domain can not be null");
    Network vNetwork = checkNotNull(network, "network can not be null");

    final StellarToml toml = await StellarToml.fromDomain(vDomain);

    if (toml.generalInformation.webAuthEndpoint == null) {
      throw Exception("No WEB_AUTH_ENDPOINT found in stellar.toml");
    }
    if (toml.generalInformation.signingKey == null) {
      throw Exception("No auth server SIGNING_KEY found in stellar.toml");
    }

    return new WebAuth(toml.generalInformation.webAuthEndpoint, vNetwork,
        toml.generalInformation.signingKey, vDomain);
  }

  /// Get JWT token for wallet.
  /// - Parameter clientAccountId: The account id of the client/user to get the JWT token for.
  /// - Parameter signers: list of signers (keypairs including secret seed) of the client account
  /// - Parameter homeDomain: optional, used for requesting the challenge depending on the home domain if needed. The web auth server may serve multiple home domains.
  /// - Parameter clientDomain: optional, domain of the client hosting it's stellar.toml
  /// - Parameter clientDomainAccountKeyPair: optional, KeyPair of the client domain account including the seed (mandatory and used for signing the transaction if client domain is provided)
  Future<String> jwtToken(String clientAccountId, List<KeyPair> signers,
      {String homeDomain,
      String clientDomain,
      KeyPair clientDomainAccountKeyPair}) async {
    String accountId =
        checkNotNull(clientAccountId, "clientAccountId can not be null");
    checkNotNull(signers, "signers can not be null");

    // get the challenge transaction from the web auth server
    String transaction =
        await getChallenge(accountId, homeDomain, clientDomain);

    String clientDomainAccountId = null;
    if (clientDomainAccountKeyPair != null) {
      clientDomainAccountId = clientDomainAccountKeyPair.accountId;
    }
    // validate the transaction received from the web auth server.
    validateChallenge(
        transaction, accountId, clientDomainAccountId); // throws if not valid

    if (clientDomainAccountKeyPair != null) {
      signers.add(clientDomainAccountKeyPair);
    }
    // sign the transaction received from the web auth server using the provided user/client keypair by parameter.
    final signedTransaction = signTransaction(transaction, signers);

    // request the jwt token by sending back the signed challenge transaction to the web auth server.
    final String jwtToken =
        await sendSignedChallengeTransaction(signedTransaction);

    return jwtToken;
  }

  /// Get challenge transaction from the web auth server. Returns base64 xdr transaction envelope received from the web auth server.
  /// - Parameter clientAccountId: The account id of the client/user that requests the challenge.
  /// - Parameter homeDomain: optional, used for requesting the challenge depending on the home domain if needed. The web auth server may serve multiple home domains.
  Future<String> getChallenge(String clientAccountId,
      [String homeDomain, String clientDomain]) async {
    ChallengeResponse challengeResponse =
        await getChallengeResponse(clientAccountId, homeDomain);

    String transaction = challengeResponse.transaction;
    if (transaction == null) {
      throw Exception("Error parsing challenge response");
    }
    return transaction;
  }

  /// Validates the challenge transaction received from the web auth server.
  void validateChallenge(String challengeTransaction, String userAccountId,
      String clientDomainAccountId) {
    final String trans =
        checkNotNull(challengeTransaction, "transaction can not be null");

    final accountId =
        checkNotNull(userAccountId, "userAccountId can not be null");

    XdrTransactionEnvelope envelopeXdr =
        XdrTransactionEnvelope.fromEnvelopeXdrString(trans);

    if (envelopeXdr.discriminant != XdrEnvelopeType.ENVELOPE_TYPE_TX) {
      throw ChallengeValidationError(
          "Invalid transaction type received in challenge");
    }

    final transaction = envelopeXdr.v1.tx;

    if (transaction.seqNum.sequenceNumber.int64 != 0) {
      throw ChallengeValidationErrorInvalidSeqNr(
          "Invalid transaction, sequence number not 0");
    }

    if (transaction.operations.length == 0) {
      throw ChallengeValidationError("invalid number of operations (0)");
    }

    for (int i = 0; i < transaction.operations.length; i++) {
      final op = transaction.operations[i];
      if (op.sourceAccount == null) {
        throw ChallengeValidationErrorInvalidSourceAccount(
            "invalid source account (is null) in operation[$i]");
      }
      if (op.sourceAccount.discriminant != XdrCryptoKeyType.KEY_TYPE_ED25519 ||
          op.sourceAccount.ed25519 == null) {
        throw ChallengeValidationErrorInvalidSourceAccount(
            "invalid source account type in operation[$i]");
      }

      final opSourceAccountId =
          StrKey.encodeStellarAccountId(op.sourceAccount.ed25519.uint256);
      if (i == 0 && opSourceAccountId != accountId) {
        throw ChallengeValidationErrorInvalidSourceAccount(
            "invalid source account in operation[$i]");
      }

      // all operations must be manage data operations
      if (op.body.discriminant != XdrOperationType.MANAGE_DATA ||
          op.body.manageDataOp == null) {
        throw ChallengeValidationErrorInvalidOperationType(
            "invalid type of operation $i");
      }

      final dataName = op.body.manageDataOp.dataName.string64;
      if (i > 0) {
        if (dataName == "client_domain") {
          if (opSourceAccountId != clientDomainAccountId) {
            throw ChallengeValidationErrorInvalidSourceAccount(
                "invalid source account in operation[$i]");
          }
        } else if (opSourceAccountId != _serverSigningKey) {
          throw ChallengeValidationErrorInvalidSourceAccount(
              "invalid source account in operation[$i]");
        }
      }

      if (i == 0 && dataName != _serverHomeDomain + " auth") {
        throw ChallengeValidationErrorInvalidHomeDomain(
            "invalid home domain in operation $i");
      }
      final dataValue = op.body.manageDataOp.dataValue.dataValue;
      if (i > 0 && dataName == "web_auth_domain") {
        final uri = Uri.parse(_authEndpoint);
        if (uri.host != String.fromCharCodes(dataValue)) {
          throw ChallengeValidationErrorInvalidWebAuthDomain(
              "invalid web auth domain in operation $i");
        }
      }
    }

    // check timebounds
    final timeBounds = transaction.timeBounds;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    if (timeBounds != null &&
        timeBounds.minTime != null &&
        timeBounds.maxTime != null) {
      if (currentTime < timeBounds.minTime.uint64 ||
          currentTime > timeBounds.maxTime.uint64) {
        throw ChallengeValidationErrorInvalidTimeBounds(
            "Invalid transaction, invalid time bounds");
      }
    }

    // the envelope must have one signature and it must be valid: transaction signed by the server
    final signatures = envelopeXdr.v1.signatures;
    if (signatures.length != 1) {
      throw ChallengeValidationErrorInvalidSignature(
          "Invalid transaction envelope, invalid number of signatures");
    }
    final firstSignature = envelopeXdr.v1.signatures[0];
    // validate signature
    final serverKeyPair = KeyPair.fromAccountId(_serverSigningKey);
    final transactionHash =
        AbstractTransaction.fromEnvelopeXdr(envelopeXdr).hash(_network);
    final valid = serverKeyPair.verify(
        transactionHash, firstSignature.signature.signature);
    if (!valid) {
      throw ChallengeValidationErrorInvalidSignature(
          "Invalid transaction envelope, invalid signature");
    }
  }

  String signTransaction(String challengeTransaction, List<KeyPair> signers) {
    final String trans =
        checkNotNull(challengeTransaction, "transaction can not be null");
    checkNotNull(signers, "signers can not be null");

    XdrTransactionEnvelope envelopeXdr =
        XdrTransactionEnvelope.fromEnvelopeXdrString(trans);

    if (envelopeXdr.discriminant != XdrEnvelopeType.ENVELOPE_TYPE_TX) {
      throw ChallengeValidationError("Invalid transaction type");
    }

    final txHash =
        AbstractTransaction.fromEnvelopeXdr(envelopeXdr).hash(_network);

    List<XdrDecoratedSignature> signatures = List<XdrDecoratedSignature>();
    signatures.addAll(envelopeXdr.v1.signatures);
    for (KeyPair signer in signers) {
      signatures.add(signer.signDecorated(txHash));
    }
    envelopeXdr.v1.signatures = signatures;
    return envelopeXdr.toEnvelopeXdrBase64();
  }

  /// Sends the signed challenge transaction back to the web auth server to obtain the jwt token.
  /// In case of success, it returns the jwt token obtained from the web auth server.
  Future<String> sendSignedChallengeTransaction(
      String base64EnvelopeXDR) async {
    Uri serverURI = Uri.parse(_authEndpoint);

    SubmitCompletedChallengeResponse result = await httpClient
        .post(serverURI,
            body: base64EnvelopeXDR, headers: RequestBuilder.headers)
        .then((response) {
      SubmitCompletedChallengeResponse submitTransactionResponse;
      switch (response.statusCode) {
        case 200:
        case 400:
          submitTransactionResponse = SubmitCompletedChallengeResponse.fromJson(
              json.decode(response.body));
          break;
        case 504:
          throw new SubmitCompletedChallengeTimeoutResponseException();
        default:
          throw new SubmitCompletedChallengeUnknownResponseException(
              response.statusCode, response.body);
      }
      return submitTransactionResponse;
    }).catchError((onError) {
      throw onError;
    });

    if (result.error != null) {
      throw SubmitCompletedChallengeErrorResponseException(result.error);
    }

    return result.jwtToken;
  }

  Future<ChallengeResponse> getChallengeResponse(String accountId,
      [String homeDomain, String clientDomain]) async {
    String id = checkNotNull(accountId, "accountId can not be null");

    Uri serverURI = Uri.parse(_authEndpoint);
    try {
      _ChallengeRequestBuilder requestBuilder =
          new _ChallengeRequestBuilder(httpClient, serverURI);
      ChallengeResponse response = await requestBuilder
          .forAccountId(id)
          .forHomeDomain(homeDomain)
          .forClientDomain(clientDomain)
          .execute();
      return response;
    } catch (e) {
      if (e is ErrorResponse) {
        throw new ChallengeRequestErrorResponse(e.code, e.body);
      } else {
        throw e;
      }
    }
  }
}

// Requests the challenge data.
class _ChallengeRequestBuilder extends RequestBuilder {
  _ChallengeRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  Future<ChallengeResponse> challengeURI(Uri uri) async {
    TypeToken type = new TypeToken<ChallengeResponse>();
    ResponseHandler<ChallengeResponse> responseHandler =
        ResponseHandler<ChallengeResponse>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  _ChallengeRequestBuilder forAccountId(String accountId) {
    queryParameters.addAll({"account": accountId});
    return this;
  }

  _ChallengeRequestBuilder forHomeDomain(String homeDomain) {
    if (homeDomain != null) {
      queryParameters.addAll({"home_domain": homeDomain});
    }
    return this;
  }

  _ChallengeRequestBuilder forClientDomain(String clientDomain) {
    if (clientDomain != null) {
      queryParameters.addAll({"client_domain": clientDomain});
    }
    return this;
  }

  _ChallengeRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<ChallengeResponse> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<ChallengeResponse>();
    ResponseHandler<ChallengeResponse> responseHandler =
        new ResponseHandler<ChallengeResponse>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<ChallengeResponse> execute() {
    return _ChallengeRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }
}

class ChallengeRequestErrorResponse extends ErrorResponse {
  ChallengeRequestErrorResponse(int code, String body) : super(code, body);
}

class ChallengeValidationError implements Exception {
  String _message;

  ChallengeValidationError(this._message);

  String toString() {
    return _message;
  }
}

class ChallengeValidationErrorInvalidSeqNr extends ChallengeValidationError {
  ChallengeValidationErrorInvalidSeqNr(String message) : super(message);
}

class ChallengeValidationErrorInvalidSourceAccount
    extends ChallengeValidationError {
  ChallengeValidationErrorInvalidSourceAccount(String message) : super(message);
}

class ChallengeValidationErrorInvalidTimeBounds
    extends ChallengeValidationError {
  ChallengeValidationErrorInvalidTimeBounds(String message) : super(message);
}

class ChallengeValidationErrorInvalidOperationType
    extends ChallengeValidationError {
  ChallengeValidationErrorInvalidOperationType(String message) : super(message);
}

class ChallengeValidationErrorInvalidHomeDomain
    extends ChallengeValidationError {
  ChallengeValidationErrorInvalidHomeDomain(String message) : super(message);
}

class ChallengeValidationErrorInvalidWebAuthDomain
    extends ChallengeValidationError {
  ChallengeValidationErrorInvalidWebAuthDomain(String message) : super(message);
}

class ChallengeValidationErrorInvalidSignature
    extends ChallengeValidationError {
  ChallengeValidationErrorInvalidSignature(String message) : super(message);
}

class SubmitCompletedChallengeTimeoutResponseException implements Exception {
  String toString() {
    return "Timeout.";
  }
}

class SubmitCompletedChallengeUnknownResponseException implements Exception {
  int _code;
  String _body;

  SubmitCompletedChallengeUnknownResponseException(this._code, this._body);

  String toString() {
    return "Unknown response - code: $code - body:$body";
  }

  int get code => _code;

  String get body => _body;
}

class SubmitCompletedChallengeErrorResponseException implements Exception {
  String _error;

  SubmitCompletedChallengeErrorResponseException(this._error);

  String toString() {
    return "Error requesting jwtToken - error:$_error";
  }

  String get error => _error;
}
