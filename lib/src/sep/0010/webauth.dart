// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../0001/stellar_toml.dart';
import '../../transaction.dart';
import '../../key_pair.dart';
import '../../muxed_account.dart';
import '../../network.dart';
import '../../util.dart';
import '../../responses/response.dart';
import '../../responses/challenge_response.dart';
import '../../requests/request_builder.dart';
import '../../xdr/xdr_transaction.dart';
import '../../xdr/xdr_operation.dart';
import '../../xdr/xdr_memo.dart';
import '../../xdr/xdr_signing.dart';

class WebAuth {
  String? _authEndpoint;
  String? _serverSigningKey;
  Network? _network;
  String? _serverHomeDomain;
  http.Client httpClient = new http.Client();
  int gracePeriod = 60 * 5;

  /// Constructor
  /// - Parameter authEndpoint: Endpoint to be used for the authentication procedure. Usually taken from stellar.toml.
  /// - Parameter network: The network used.
  /// - Parameter serverSigningKey: The server public key, taken from stellar.toml.
  /// - Parameter serverHomeDomain: The server home domain of the server where the stellar.toml was loaded from
  WebAuth(this._authEndpoint, this._network, this._serverSigningKey,
      this._serverHomeDomain);

  /// Creates a WebAuth instance by loading the needed data from the stellar.toml file hosted on the given domain.
  /// e.g. fromDomain("soneso.com", Network.TESTNET)
  /// - Parameter domain: The domain from which to get the stellar information
  /// - Parameter network: The network used.
  static Future<WebAuth> fromDomain(String domain, Network network) async {

    final StellarToml toml = await StellarToml.fromDomain(domain);

    if (toml.generalInformation.webAuthEndpoint == null) {
      throw Exception("No WEB_AUTH_ENDPOINT found in stellar.toml");
    }
    if (toml.generalInformation.signingKey == null) {
      throw Exception("No auth server SIGNING_KEY found in stellar.toml");
    }

    return new WebAuth(toml.generalInformation.webAuthEndpoint, network,
        toml.generalInformation.signingKey, domain);
  }

  /// Get JWT token for wallet.
  /// - Parameter clientAccountId: The account id of the client/user to get the JWT token for.
  /// - Parameter signers: list of signers (keypairs including secret seed) of the client account
  /// - Parameter memo: optional, ID memo of the client account if muxed and accountId starts with G
  /// - Parameter homeDomain: optional, used for requesting the challenge depending on the home domain if needed. The web auth server may serve multiple home domains.
  /// - Parameter clientDomain: optional, domain of the client hosting it's stellar.toml
  /// - Parameter clientDomainAccountKeyPair: optional, KeyPair of the client domain account including the seed (mandatory and used for signing the transaction if client domain is provided)
  Future<String> jwtToken(String clientAccountId, List<KeyPair> signers,
      {int? memo,
      String? homeDomain,
      String? clientDomain,
      KeyPair? clientDomainAccountKeyPair}) async {

    // get the challenge transaction from the web auth server
    String transaction =
        await getChallenge(clientAccountId, memo, homeDomain, clientDomain);

    String? clientDomainAccountId;
    if (clientDomainAccountKeyPair != null) {
      clientDomainAccountId = clientDomainAccountKeyPair.accountId;
    }
    // validate the transaction received from the web auth server.
    validateChallenge(transaction, clientAccountId, clientDomainAccountId,
        gracePeriod, memo); // throws if not valid

    List<KeyPair> mSigners = List.from(signers, growable: true);
    if (clientDomainAccountKeyPair != null) {
      mSigners.add(clientDomainAccountKeyPair);
    }
    // sign the transaction received from the web auth server using the provided user/client keypair by parameter.
    final signedTransaction = signTransaction(transaction, mSigners);

    // request the jwt token by sending back the signed challenge transaction to the web auth server.
    final String jwtToken =
        await sendSignedChallengeTransaction(signedTransaction);

    return jwtToken;
  }

  /// Get challenge transaction from the web auth server. Returns base64 xdr transaction envelope received from the web auth server.
  /// - Parameter clientAccountId: The account id of the client/user that requests the challenge.
  /// - Parameter memo: optional, ID memo of the client account if muxed and accountId starts with G
  /// - Parameter homeDomain: optional, used for requesting the challenge depending on the home domain if needed. The web auth server may serve multiple home domains.
  /// - Parameter clientDomain: optional, domain of the client hosting it's stellar.toml
  Future<String> getChallenge(String clientAccountId,
      [int? memo, String? homeDomain, String? clientDomain]) async {
    ChallengeResponse challengeResponse =
        await getChallengeResponse(clientAccountId, memo, homeDomain);

    String? transaction = challengeResponse.transaction;
    if (transaction == null) {
      throw Exception("Error parsing challenge response");
    }
    return transaction;
  }

  /// Validates the challenge transaction received from the web auth server.
  void validateChallenge(String challengeTransaction, String userAccountId,
      String? clientDomainAccountId,
      [int? timeBoundsGracePeriod, int? memo]) {

    XdrTransactionEnvelope envelopeXdr =
        XdrTransactionEnvelope.fromEnvelopeXdrString(challengeTransaction);

    if (envelopeXdr.discriminant != XdrEnvelopeType.ENVELOPE_TYPE_TX) {
      throw ChallengeValidationError(
          "Invalid transaction type received in challenge");
    }

    final transaction = envelopeXdr.v1!.tx;

    if (transaction.seqNum.sequenceNumber.int64 != 0) {
      throw ChallengeValidationErrorInvalidSeqNr(
          "Invalid transaction, sequence number not 0");
    }

    if (transaction.memo.discriminant != XdrMemoType.MEMO_NONE) {
      if (userAccountId.startsWith("M")) {
        throw ChallengeValidationErrorMemoAndMuxedAccount(
            "Memo and muxed account (M...) found");
      } else if (transaction.memo.discriminant != XdrMemoType.MEMO_ID) {
        throw ChallengeValidationErrorInvalidMemoType("invalid memo type");
      } else if (memo != null && transaction.memo.id!.uint64 != memo) {
        throw ChallengeValidationErrorInvalidMemoValue("invalid memo value");
      }
    } else if (memo != null) {
      throw ChallengeValidationErrorInvalidMemoValue("missing memo");
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

      final opSourceAccountId =
          MuxedAccount.fromXdr(op.sourceAccount!).accountId;
      if (i == 0 && opSourceAccountId != userAccountId) {
        throw ChallengeValidationErrorInvalidSourceAccount(
            "invalid source account in operation[$i]");
      }

      // all operations must be manage data operations
      if (op.body.discriminant != XdrOperationType.MANAGE_DATA ||
          op.body.manageDataOp == null) {
        throw ChallengeValidationErrorInvalidOperationType(
            "invalid type of operation $i");
      }

      final dataName = op.body.manageDataOp!.dataName.string64;
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

      if (i == 0 && dataName != _serverHomeDomain! + " auth") {
        throw ChallengeValidationErrorInvalidHomeDomain(
            "invalid home domain in operation $i");
      }
      final dataValue = op.body.manageDataOp!.dataValue!.dataValue;
      if (i > 0 && dataName == "web_auth_domain") {
        final uri = Uri.parse(_authEndpoint!);
        if (uri.host != String.fromCharCodes(dataValue)) {
          throw ChallengeValidationErrorInvalidWebAuthDomain(
              "invalid web auth domain in operation $i");
        }
      }
    }

    // check timebounds
    final timeBounds = transaction.preconditions.timeBounds;
    if (timeBounds != null) {
      int grace = 0;
      if (timeBoundsGracePeriod != null) {
        grace = timeBoundsGracePeriod;
      }
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (currentTime < timeBounds.minTime.uint64 - grace ||
          currentTime > timeBounds.maxTime.uint64 + grace) {
        throw ChallengeValidationErrorInvalidTimeBounds(
            "Invalid transaction, invalid time bounds");
      }
    }

    // the envelope must have one signature and it must be valid: transaction signed by the server
    final signatures = envelopeXdr.v1!.signatures;
    if (signatures.length != 1) {
      throw ChallengeValidationErrorInvalidSignature(
          "Invalid transaction envelope, invalid number of signatures");
    }
    final firstSignature = envelopeXdr.v1!.signatures[0];
    // validate signature
    final serverKeyPair = KeyPair.fromAccountId(_serverSigningKey!);
    final transactionHash =
        AbstractTransaction.fromEnvelopeXdr(envelopeXdr).hash(_network!);
    final valid = serverKeyPair.verify(
        transactionHash, firstSignature.signature!.signature!);
    if (!valid) {
      throw ChallengeValidationErrorInvalidSignature(
          "Invalid transaction envelope, invalid signature");
    }
  }

  String signTransaction(
      String challengeTransaction, List<KeyPair> signers) {

    XdrTransactionEnvelope envelopeXdr =
        XdrTransactionEnvelope.fromEnvelopeXdrString(challengeTransaction);

    if (envelopeXdr.discriminant != XdrEnvelopeType.ENVELOPE_TYPE_TX) {
      throw ChallengeValidationError("Invalid transaction type");
    }

    final txHash =
        AbstractTransaction.fromEnvelopeXdr(envelopeXdr).hash(_network!);

    List<XdrDecoratedSignature> signatures =
        List<XdrDecoratedSignature>.empty(growable: true);
    signatures.addAll(envelopeXdr.v1!.signatures);
    for (KeyPair signer in signers) {
      signatures.add(signer.signDecorated(txHash));
    }
    envelopeXdr.v1!.signatures = signatures;
    return envelopeXdr.toEnvelopeXdrBase64();
  }

  /// Sends the signed challenge transaction back to the web auth server to obtain the jwt token.
  /// In case of success, it returns the jwt token obtained from the web auth server.
  Future<String> sendSignedChallengeTransaction(
      String base64EnvelopeXDR) async {
    Uri serverURI = Uri.parse(_authEndpoint!);

    Map<String, String> headers = {...RequestBuilder.headers};
    headers.putIfAbsent("Content-Type", () => "application/json");

    SubmitCompletedChallengeResponse result = await httpClient
        .post(serverURI,
            body: json.encode({"transaction": base64EnvelopeXDR}),
            headers: headers)
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
      throw SubmitCompletedChallengeErrorResponseException(result.error!);
    }

    return result.jwtToken!;
  }

  Future<ChallengeResponse> getChallengeResponse(String accountId,
      [int? memo, String? homeDomain, String? clientDomain]) async {
    if (memo != null && accountId.startsWith("M")) {
      throw new Exception(
          "memo cannot be used if accountId is a muxed account");
    }

    Uri serverURI = Uri.parse(_authEndpoint!);
    try {
      _ChallengeRequestBuilder requestBuilder =
          new _ChallengeRequestBuilder(httpClient, serverURI);
      ChallengeResponse response = await requestBuilder
          .forAccountId(accountId)
          .forHomeDomain(homeDomain)
          .forClientDomain(clientDomain)
          .forMemo(memo)
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
    TypeToken<ChallengeResponse> type = new TypeToken<ChallengeResponse>();
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

  _ChallengeRequestBuilder forHomeDomain(String? homeDomain) {
    if (homeDomain != null) {
      queryParameters.addAll({"home_domain": homeDomain});
    }
    return this;
  }

  _ChallengeRequestBuilder forMemo(int? memo) {
    if (memo != null) {
      queryParameters.addAll({"memo": memo.toString()});
    }
    return this;
  }

  _ChallengeRequestBuilder forClientDomain(String? clientDomain) {
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
    TypeToken<ChallengeResponse> type = new TypeToken<ChallengeResponse>();
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

class ChallengeValidationErrorMemoAndMuxedAccount
    extends ChallengeValidationError {
  ChallengeValidationErrorMemoAndMuxedAccount(String message) : super(message);
}

class ChallengeValidationErrorInvalidMemoType extends ChallengeValidationError {
  ChallengeValidationErrorInvalidMemoType(String message) : super(message);
}

class ChallengeValidationErrorInvalidMemoValue
    extends ChallengeValidationError {
  ChallengeValidationErrorInvalidMemoValue(String message) : super(message);
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
