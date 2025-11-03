// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import 'request_builder.dart';
import '../responses/response.dart';
import '../responses/fee_stats_response.dart';

/// Fee stats are used to predict what fee to set for a transaction before submitting it to the network.
/// See: [Fee stats](https://developers.stellar.org/api/aggregations/fee-stats/)
class FeeStatsRequestBuilder extends RequestBuilder {
  FeeStatsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["fee_stats"]);

  /// Requests fee stats from horizon.
  /// See: [Fee stats](https://developers.stellar.org/api/aggregations/fee-stats/)
  Future<FeeStatsResponse> execute() async {
    TypeToken<FeeStatsResponse> type = new TypeToken<FeeStatsResponse>();
    ResponseHandler<FeeStatsResponse> responseHandler = new ResponseHandler<FeeStatsResponse>(type);

    return await httpClient.get(this.buildUri(), headers: RequestBuilder.headers).then((response) {
      return responseHandler.handleResponse(response);
    });
  }
}
