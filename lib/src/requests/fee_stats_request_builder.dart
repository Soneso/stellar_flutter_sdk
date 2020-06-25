// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import 'request_builder.dart';
import '../responses/response.dart';
import '../responses/fee_stats_response.dart';

class OperationFeeStatsRequestBuilder extends RequestBuilder {
  OperationFeeStatsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["operation_fee_stats"]);

  /// Requests <code>GET /operation_fee_stats</code>
  Future<FeeStatsResponse> execute() async {
    TypeToken type = new TypeToken<FeeStatsResponse>();
    ResponseHandler<FeeStatsResponse> responseHandler =
        new ResponseHandler<FeeStatsResponse>(type);

    return await httpClient
        .get(this.buildUri(), headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }
}
