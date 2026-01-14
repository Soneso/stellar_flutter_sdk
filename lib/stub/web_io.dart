// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// Stub for dart:io File class on web platform.
///
/// File system operations are not available in web browsers due to
/// security restrictions. Use file picker APIs or fetch from URLs instead.
class File {
  final Uri _uri;

  File.fromUri(Uri uri) : _uri = uri;

  Future<List<int>> readAsBytes() => throw UnsupportedError(
      'File operations not available on web. '
      'Attempted to read: $_uri. '
      'Use file picker or fetch from URL instead.');
}
