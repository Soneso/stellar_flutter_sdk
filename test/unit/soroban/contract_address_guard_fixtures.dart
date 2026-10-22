import 'package:flutter_test/flutter_test.dart';

/// The SEP-23 contract, its muxed contract with id 123456, a muxed account
/// and an account.
const sep23Contract =
    'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';
const sep23MuxedContract =
    'WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG';
const sep23MuxedAccount =
    'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK';
const sep23Account = 'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ';

/// A valid secret seed, which no guard message may repeat.
const secretSeed = 'SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36XCU';

/// The messages that reject [sep23MuxedContract] and [sep23MuxedAccount]
/// given as the contract of [subject].
Map<String, String> nonContractMessages(String subject) {
  final prefix = '$subject must be a contract (C...) address';
  return {
    sep23MuxedContract:
        '$prefix, got a muxed contract (W...) address: $sep23MuxedContract; '
        'use its base contract (C...) address',
    sep23MuxedAccount:
        '$prefix, got a muxed account (M...) address: $sep23MuxedAccount',
  };
}

/// Matches a call or future that throws an [ArgumentError] with [message].
Matcher throwsRejection(String message) =>
    throwsA(isA<ArgumentError>().having((e) => e.message, 'message', message));
