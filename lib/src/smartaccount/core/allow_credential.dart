// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

/// A credential descriptor pairing a credential ID with optional transport
/// hints (`internal`, `hybrid`, `usb`, `ble`, `nfc`).
///
/// When [transports] is `null`, the authenticator uses its default transport
/// selection. Equality is byte-content-based on [id]; [id] is stored by
/// reference.
class AllowCredential {
  /// The raw credential ID bytes. Stored by reference; mutating the original
  /// array will be reflected here.
  final Uint8List id;

  /// Optional list of transport hints (e.g. `internal`, `hybrid`, `usb`,
  /// `ble`, `nfc`). `null` means the authenticator picks the transport.
  final List<String>? transports;

  /// Constructs an [AllowCredential] from a raw credential [id] and optional
  /// [transports].
  const AllowCredential({required this.id, this.transports});

  /// Creates an [AllowCredential] from a raw credential [id] with no
  /// transport hints.
  static AllowCredential fromId(Uint8List id) => AllowCredential(id: id);

  /// Creates a list of [AllowCredential] from raw credential [ids] with no
  /// transport hints.
  static List<AllowCredential> fromIds(List<Uint8List> ids) =>
      ids.map(AllowCredential.fromId).toList(growable: false);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AllowCredential) return false;
    if (!_byteListEquals(id, other.id)) return false;
    return _transportsEquals(transports, other.transports);
  }

  @override
  int get hashCode {
    final transportsHash = transports == null
        ? 0
        : Object.hashAll(transports as Iterable<Object?>);
    return Object.hash(_byteListHash(id), transportsHash);
  }

  /// Byte-content equality over [a] and [b].
  static bool _byteListEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var acc = 0;
    for (var i = 0; i < a.length; i++) {
      acc |= a[i] ^ b[i];
    }
    return acc == 0;
  }

  /// Computes a hash code over the bytes of [data] equivalent in spirit to
  /// Java's `Arrays.hashCode(byte[])`, so that byte-equal arrays produce the
  /// same hash code.
  static int _byteListHash(Uint8List data) {
    var result = 1;
    for (var i = 0; i < data.length; i++) {
      result = 31 * result + (data[i] & 0xFF);
    }
    return result;
  }

  /// Compares two transport lists, distinguishing `null` from the empty
  /// list (`null` and `[]` are NOT considered equal, mirroring the source
  /// reference).
  static bool _transportsEquals(List<String>? a, List<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
