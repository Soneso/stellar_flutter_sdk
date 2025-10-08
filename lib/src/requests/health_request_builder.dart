// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import 'request_builder.dart';
import '../responses/response.dart';
import '../responses/health_response.dart';

/// Builds requests connected to the health endpoint of the Horizon server.
/// Health endpoint provides information about the current operational status of the Horizon server.
/// See: <a href="https://developers.stellar.org/docs/data/horizon/api-reference/structure/health" target="_blank">Health endpoint</a>
class HealthRequestBuilder extends RequestBuilder {
  /// Creates a new HealthRequestBuilder instance.
  /// [httpClient] - The HTTP client to use for requests.
  /// [serverURI] - The base URI of the Horizon server.
  HealthRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["health"]);

  /// Requests health status from the Horizon server.
  /// Returns a [Future] that resolves to a [HealthResponse] containing the server's health status.
  ///
  /// The response includes:
  /// - databaseConnected: Whether the Horizon database is connected
  /// - coreUp: Whether the Stellar Core instance is up and running
  /// - coreSynced: Whether the Stellar Core instance is synced with the network
  ///
  /// The server is considered healthy when all three values are true.
  ///
  /// Throws [UnknownResponse] if the server response could not be interpreted.
  /// Throws [http.ClientException] if there is a transport-level failure.
  ///
  /// Example:
  /// ```dart
  /// final sdk = StellarSDK.PUBLIC;
  /// final health = await sdk.health.execute();
  /// if (health.isHealthy) {
  ///   print('Server is healthy');
  ///   print('Database connected: ${health.databaseConnected}');
  ///   print('Core up: ${health.coreUp}');
  ///   print('Core synced: ${health.coreSynced}');
  /// }
  /// ```
  Future<HealthResponse> execute() async {
    TypeToken<HealthResponse> type = TypeToken<HealthResponse>();
    ResponseHandler<HealthResponse> responseHandler =
        ResponseHandler<HealthResponse>(type);

    return await httpClient
        .get(this.buildUri(), headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }
}