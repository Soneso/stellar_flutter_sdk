// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

/// A credential descriptor pairing a credential ID with optional transport
/// hints.
///
/// Used in [WebAuthnProvider.authenticate](web_authn_provider.dart) to
/// constrain which passkeys the authenticator offers and to indicate how the
/// client can reach the authenticator (`internal`, `hybrid`, `usb`, `ble`,
/// `nfc`). Including transport hints enables cross-device authentication
/// flows such as QR-code scanning.
///
/// When [transports] is `null`, the authenticator uses its default transport
/// selection. Unknown transport strings are passed through without
/// validation; the browser or platform ignores values it does not recognise.
///
/// Equality is byte-content-based on [id] (so two instances with separately
/// allocated arrays of identical bytes compare equal) and value-equal on the
/// [transports] list. The [id] field is stored by reference; callers that
/// want isolation must copy the array themselves.
///
/// Instances are immutable and isolate-safe: every field is `final` and the
/// class exposes no mutating operations. Sharing instances across isolates
/// is supported without external synchronisation, provided callers do not
/// mutate the byte array or transports list they passed into the
/// constructor.
///
/// Example:
/// ```dart
/// final credential = AllowCredential(
///   id: Uint8List.fromList(rawCredentialId),
///   transports: const ['internal', 'hybrid'],
/// );
/// ```
class AllowCredential {
  /// The raw credential ID bytes.
  ///
  /// Stored by reference; mutating the original array will be reflected in
  /// this field.
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

  /// Compares two byte lists for equality without short-circuiting on the
  /// first differing byte.
  ///
  /// Length difference returns `false` immediately (length is not protected
  /// by this comparison). Past the length check, every byte position is
  /// compared so the timing does not depend on which position differs.
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
