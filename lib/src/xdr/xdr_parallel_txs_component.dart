// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_parallel_tx_execution_stage.dart';

class XdrParallelTxsComponent {
  XdrInt64? _baseFee;
  XdrInt64? get baseFee => this._baseFee;
  set baseFee(XdrInt64? value) => this._baseFee = value;

  List<XdrParallelTxExecutionStage> _executionStages;
  List<XdrParallelTxExecutionStage> get executionStages =>
      this._executionStages;
  set executionStages(List<XdrParallelTxExecutionStage> value) =>
      this._executionStages = value;

  XdrParallelTxsComponent(this._baseFee, this._executionStages);

  static void encode(
    XdrDataOutputStream stream,
    XdrParallelTxsComponent encodedParallelTxsComponent,
  ) {
    if (encodedParallelTxsComponent.baseFee != null) {
      stream.writeInt(1);
      XdrInt64.encode(stream, encodedParallelTxsComponent.baseFee!);
    } else {
      stream.writeInt(0);
    }
    int executionStagessize =
        encodedParallelTxsComponent.executionStages.length;
    stream.writeInt(executionStagessize);
    for (int i = 0; i < executionStagessize; i++) {
      XdrParallelTxExecutionStage.encode(
        stream,
        encodedParallelTxsComponent.executionStages[i],
      );
    }
  }

  static XdrParallelTxsComponent decode(XdrDataInputStream stream) {
    XdrInt64? baseFee;
    int baseFeePresent = stream.readInt();
    if (baseFeePresent != 0) {
      baseFee = XdrInt64.decode(stream);
    }
    int executionStagessize = stream.readInt();
    List<XdrParallelTxExecutionStage> executionStages =
        List<XdrParallelTxExecutionStage>.empty(growable: true);
    for (int i = 0; i < executionStagessize; i++) {
      executionStages.add(XdrParallelTxExecutionStage.decode(stream));
    }
    return XdrParallelTxsComponent(baseFee, executionStages);
  }
}
