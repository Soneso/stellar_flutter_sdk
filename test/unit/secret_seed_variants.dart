// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// The wording a message uses in place of a valid secret seed.
const String seedWording = 'a secret seed (S...)';

/// The wording a message uses in place of any other value that starts with
/// `S` or `s`.
const String seedLikeWording =
    'a value starting with S (not shown, it may be a secret seed)';

/// A secret seed generated at run time and the near-seeds derived from it.
class SeedVariants {
  /// A valid secret seed.
  final String seed = KeyPair.random().secretSeed;

  /// The seed with its eleventh character replaced, so its checksum fails.
  String get changed => _replaceAt(10, seed[10] == 'A' ? 'B' : 'A');

  /// The seed with its eleventh character replaced by a digit outside the
  /// base32 alphabet.
  String get digit => _replaceAt(10, '1');

  /// The seed in lower case.
  String get lowercase => seed.toLowerCase();

  /// The seed without its last character.
  String get missing => seed.substring(0, seed.length - 1);

  /// The seed with one character added.
  String get extra => '${seed}A';

  /// Every variant by name.
  Map<String, String> get all => {
    'valid seed': seed,
    'seed with a changed character': changed,
    'seed with a digit outside base32': digit,
    'lowercase seed': lowercase,
    'seed with a character missing': missing,
    'seed with a character added': extra,
  };

  /// The wording a key position message gives [value], one of [all]: the
  /// seed wording for a valid seed in either letter case, the other wording
  /// for a near-seed.
  String keyWording(String value) =>
      value == seed || value == lowercase ? seedWording : seedLikeWording;

  String _replaceAt(int index, String character) =>
      seed.substring(0, index) + character + seed.substring(index + 1);
}

/// Matches a text that leaves out [value]: neither the value nor its 40
/// characters after the first two appear in it, in either letter case.
Matcher leavesOut(String value) => predicate<String>((text) {
  final String upper = text.toUpperCase();
  final String target = value.toUpperCase();
  return !upper.contains(target) && !upper.contains(target.substring(2, 42));
}, 'a text that leaves out the value');
