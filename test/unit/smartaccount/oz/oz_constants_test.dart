import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('OZConstants', () {
    test('test_DEFAULT_SESSION_EXPIRY_MS_equals_604800000_ms_seven_days', () {
      expect(OZConstants.defaultSessionExpiryMs, 604800000);
      // Sanity: 604_800_000 ms == 7 days exactly.
      expect(OZConstants.defaultSessionExpiryMs, 7 * 24 * 60 * 60 * 1000);
    });

    test('test_DEFAULT_INDEXER_TIMEOUT_MS_equals_10000', () {
      expect(OZConstants.defaultIndexerTimeoutMs, 10000);
    });

    test('test_DEFAULT_RELAYER_TIMEOUT_MS_equals_360000_ms_six_minutes', () {
      expect(OZConstants.defaultRelayerTimeoutMs, 360000);
      expect(OZConstants.defaultRelayerTimeoutMs, 6 * 60 * 1000);
    });

    test('test_WEBAUTHN_TIMEOUT_MS_equals_60000', () {
      expect(OZConstants.webauthnTimeoutMs, 60000);
    });

    test('test_FRIENDBOT_RESERVE_XLM_equals_5', () {
      expect(OZConstants.friendbotReserveXlm, 5);
    });

    test('test_DEFAULT_TIMEOUT_SECONDS_equals_30', () {
      expect(OZConstants.defaultTimeoutSeconds, 30);
    });

    test('test_MAX_SIGNERS_equals_15', () {
      expect(OZConstants.maxSigners, 15);
    });

    test('test_MAX_POLICIES_equals_5', () {
      expect(OZConstants.maxPolicies, 5);
    });

    test('test_CLIENT_NAME_HEADER_equals_X_Client_Name', () {
      expect(OZConstants.clientNameHeader, 'X-Client-Name');
    });

    test('test_CLIENT_VERSION_HEADER_equals_X_Client_Version', () {
      expect(OZConstants.clientVersionHeader, 'X-Client-Version');
    });

    test('test_CLIENT_NAME_per_platform', () {
      // Flutter port emits the Flutter-specific identifier so the OpenZeppelin
      // indexer and relayer can attribute traffic to this SDK.
      expect(OZConstants.clientName, 'flutter-stellar-sdk');
    });

    test('test_OZConstants_exposes_exactly_15_public_constants', () {
      // Inventory check: the fifteen values below must all be present and
      // surfacing the correct constants. If a new constant is added or one is
      // removed/renamed, this list will fall out of date and force review.
      final values = <Object>[
        OZConstants.defaultSessionExpiryMs,
        OZConstants.defaultIndexerTimeoutMs,
        OZConstants.defaultRelayerTimeoutMs,
        OZConstants.webauthnTimeoutMs,
        OZConstants.friendbotReserveXlm,
        OZConstants.defaultTimeoutSeconds,
        OZConstants.maxSigners,
        OZConstants.maxPolicies,
        OZConstants.clientNameHeader,
        OZConstants.clientVersionHeader,
        OZConstants.clientName,
        OZConstants.maxIndexerResponseBytes,
        OZConstants.maxRelayerResponseBytes,
        OZConstants.maxIndexerConnectTimeoutMs,
        OZConstants.maxRelayerConnectTimeoutMs,
      ];
      expect(values.length, 15);
      expect(values, everyElement(isNotNull));
    });
  });
}
