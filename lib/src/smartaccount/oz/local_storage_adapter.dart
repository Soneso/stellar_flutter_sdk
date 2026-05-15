// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// Public facade for the browser `localStorage`-backed storage adapter.
///
/// On Flutter web (`dart:js_interop` available) this re-exports the real
/// implementation that persists credentials and sessions to
/// `window.localStorage`. On every other target it re-exports a stub that
/// throws [UnsupportedError] from each storage method while keeping
/// construction safe.
///
/// For production web applications consider [IndexedDBStorageAdapter]
/// instead — it scales beyond the per-origin localStorage cap and offers
/// indexed lookups.
library;

export 'web/local_storage_adapter_stub.dart'
    if (dart.library.js_interop) 'web/local_storage_adapter_web.dart';
