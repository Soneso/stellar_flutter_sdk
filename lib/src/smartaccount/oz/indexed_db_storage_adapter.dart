// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// Public facade for the browser IndexedDB-backed storage adapter.
///
/// On Flutter web (`dart:js_interop` available) this re-exports the real
/// implementation that persists credentials and sessions to IndexedDB.
/// On every other target it re-exports a stub that keeps construction
/// safe and throws [UnsupportedError] from storage operations.
///
/// Recommended for production web applications: storage is much larger
/// than `localStorage`, supports structured indexing for contract-ID
/// lookups, and does not block the main thread.
library;

export 'web/indexed_db_storage_adapter_stub.dart'
    if (dart.library.js_interop) 'web/indexed_db_storage_adapter_web.dart';
