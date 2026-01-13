// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart';

/// Configures HTTP overrides for web platform.
/// Certificate overrides are not supported on web (browsers handle this).
void configureHttpOverrides(Dio dio, bool enableOverrides) {
  // No-op on web - certificate overrides not supported
}
