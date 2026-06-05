// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName =
      'com.soneso.stellar_flutter_sdk/smartaccount/webauthn.test';

  late MethodChannel channel;
  late List<MethodCall> recordedCalls;
  late Object? Function(MethodCall call) handler;

  setUp(() {
    channel = const MethodChannel(channelName);
    recordedCalls = <MethodCall>[];
    handler = (MethodCall call) => null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      recordedCalls.add(call);
      return handler(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Uint8List bytes(List<int> values) => Uint8List.fromList(values);

  PlatformWebAuthnProvider provider({String? attachment}) =>
      PlatformWebAuthnProvider(
        rpId: 'example.com',
        rpName: 'Example Wallet',
        timeout: 60000,
        authenticatorAttachment: attachment,
        methodChannel: channel,
      );

  Map<Object?, Object?> registrationResult({List<String>? transports}) {
    return <Object?, Object?>{
      'credentialId': bytes(<int>[0xa1, 0xa2, 0xa3]),
      'publicKey': bytes(List<int>.generate(65, (i) => i & 0xff)),
      'attestationObject': bytes(<int>[0xb0, 0xb1, 0xb2, 0xb3]),
      if (transports != null) 'transports': transports,
      'deviceType': 'multiDevice',
      'backedUp': true,
    };
  }

  Map<Object?, Object?> authenticationResult() {
    return <Object?, Object?>{
      'credentialId': bytes(<int>[0xc1, 0xc2]),
      'authenticatorData': bytes(<int>[0xd0, 0xd1, 0xd2]),
      'clientDataJSON': bytes(<int>[0xe0, 0xe1, 0xe2, 0xe3, 0xe4]),
      'signature': bytes(<int>[0xf0, 0xf1, 0xf2, 0xf3]),
    };
  }

  group('register', () {
    test('marshals args to method channel', () async {
      handler = (call) => registrationResult();

      await provider(attachment: 'platform').register(
        challenge: bytes(<int>[1, 2, 3, 4]),
        userId: bytes(<int>[5, 6, 7]),
        userName: 'alice@example.com',
      );

      expect(recordedCalls, hasLength(1));
      final call = recordedCalls.single;
      expect(call.method, 'register');
      final args = (call.arguments as Map).cast<String, Object?>();
      expect(args['rpId'], 'example.com');
      expect(args['rpName'], 'Example Wallet');
      expect(args['timeout'], 60000);
      expect(args['challenge'], bytes(<int>[1, 2, 3, 4]));
      expect(args['userId'], bytes(<int>[5, 6, 7]));
      expect(args['userName'], 'alice@example.com');
      expect(args['authenticatorAttachment'], 'platform');
    });

    test('demarshals native result to typed dart result', () async {
      handler = (call) => registrationResult(transports: <String>['internal']);

      final result = await provider().register(
        challenge: bytes(<int>[0x01]),
        userId: bytes(<int>[0x02]),
        userName: 'alice',
      );

      expect(result.credentialId, bytes(<int>[0xa1, 0xa2, 0xa3]));
      expect(result.publicKey.length, 65);
      expect(result.attestationObject, bytes(<int>[0xb0, 0xb1, 0xb2, 0xb3]));
      expect(result.transports, <String>['internal']);
      expect(result.deviceType, 'multiDevice');
      expect(result.backedUp, true);
    });

    test('platform exception WEBAUTHN_CANCELLED rethrows typed', () async {
      handler = (call) {
        throw PlatformException(
          code: 'WEBAUTHN_CANCELLED',
          message: 'User cancelled WebAuthn operation',
        );
      };

      try {
        await provider().register(
          challenge: bytes(<int>[1]),
          userId: bytes(<int>[2]),
          userName: 'alice',
        );
        fail('expected WebAuthnCancelled');
      } on WebAuthnCancelled catch (e) {
        expect(e.code.code, 4004);
        expect(e.message, contains('User cancelled'));
        expect(e.cause, isA<PlatformException>());
      }
    });

    test('platform exception WEBAUTHN_REGISTRATION_FAILED rethrows typed',
        () async {
      handler = (call) {
        throw PlatformException(
          code: 'WEBAUTHN_REGISTRATION_FAILED',
          message: 'Authenticator unreachable',
        );
      };

      try {
        await provider().register(
          challenge: bytes(<int>[1]),
          userId: bytes(<int>[2]),
          userName: 'alice',
        );
        fail('expected WebAuthnRegistrationFailed');
      } on WebAuthnRegistrationFailed catch (e) {
        expect(e.code.code, 4001);
        expect(e.message, contains('Authenticator unreachable'));
        expect(e.cause, isA<PlatformException>());
      }
    });

    test('platform exception unmapped code wraps as registration failed',
        () async {
      handler = (call) {
        throw PlatformException(
          code: 'SOMETHING_UNEXPECTED',
          message: 'native bug',
        );
      };

      try {
        await provider().register(
          challenge: bytes(<int>[1]),
          userId: bytes(<int>[2]),
          userName: 'alice',
        );
        fail('expected WebAuthnRegistrationFailed');
      } on WebAuthnRegistrationFailed catch (e) {
        expect(e.code.code, 4001);
        expect(e.message, contains('unexpected platform error'));
        expect(e.message, contains('SOMETHING_UNEXPECTED'));
      }
    });
  });

  group('authenticate', () {
    test('marshals args to method channel', () async {
      handler = (call) => authenticationResult();

      await provider().authenticate(
        challenge: bytes(<int>[0x10, 0x11, 0x12]),
      );

      expect(recordedCalls, hasLength(1));
      final args = (recordedCalls.single.arguments as Map).cast<String, Object?>();
      expect(args['rpId'], 'example.com');
      expect(args['timeout'], 60000);
      expect(args['challenge'], bytes(<int>[0x10, 0x11, 0x12]));
      expect(args.containsKey('allowCredentials'), false);
    });

    test('demarshals native result to typed dart result', () async {
      handler = (call) => authenticationResult();

      final result = await provider().authenticate(
        challenge: bytes(<int>[0x10]),
      );

      expect(result.credentialId, bytes(<int>[0xc1, 0xc2]));
      expect(result.authenticatorData, bytes(<int>[0xd0, 0xd1, 0xd2]));
      expect(result.clientDataJSON, bytes(<int>[0xe0, 0xe1, 0xe2, 0xe3, 0xe4]));
      expect(result.signature, bytes(<int>[0xf0, 0xf1, 0xf2, 0xf3]));
    });

    test('with allow credentials serializes transports', () async {
      handler = (call) => authenticationResult();

      await provider().authenticate(
        challenge: bytes(<int>[0x20]),
        allowCredentials: <AllowCredential>[
          AllowCredential(
            id: bytes(<int>[0x30, 0x31]),
            transports: const <String>['internal', 'hybrid'],
          ),
          AllowCredential(id: bytes(<int>[0x40])),
        ],
      );

      final args =
          (recordedCalls.single.arguments as Map).cast<String, Object?>();
      final allow = (args['allowCredentials'] as List).cast<Map>();
      expect(allow, hasLength(2));
      final first = allow[0].cast<String, Object?>();
      expect(first['id'], bytes(<int>[0x30, 0x31]));
      expect(first['transports'], <String>['internal', 'hybrid']);
      final second = allow[1].cast<String, Object?>();
      expect(second['id'], bytes(<int>[0x40]));
      expect(second.containsKey('transports'), false);
    });

    test('platform exception WEBAUTHN_AUTHENTICATION_FAILED rethrows typed',
        () async {
      handler = (call) {
        throw PlatformException(
          code: 'WEBAUTHN_AUTHENTICATION_FAILED',
          message: 'No matching credential found for example.com',
        );
      };

      try {
        await provider().authenticate(challenge: bytes(<int>[1]));
        fail('expected WebAuthnAuthenticationFailed');
      } on WebAuthnAuthenticationFailed catch (e) {
        expect(e.code.code, 4002);
        expect(e.message, contains('No matching credential'));
        expect(e.cause, isA<PlatformException>());
      }
    });

    test('platform exception WEBAUTHN_CANCELLED rethrows typed', () async {
      handler = (call) {
        throw PlatformException(
          code: 'WEBAUTHN_CANCELLED',
          message: 'User cancelled WebAuthn operation',
        );
      };

      try {
        await provider().authenticate(challenge: bytes(<int>[1]));
        fail('expected WebAuthnCancelled');
      } on WebAuthnCancelled catch (e) {
        expect(e.code.code, 4004);
      }
    });

    test('null native result throws WebAuthnAuthenticationFailed', () async {
      handler = (call) => null;

      try {
        await provider().authenticate(challenge: bytes(<int>[1]));
        fail('expected WebAuthnAuthenticationFailed');
      } on WebAuthnAuthenticationFailed catch (e) {
        expect(e.message, contains('null'));
      }
    });

    test('platform exception unmapped code wraps as authentication failed',
        () async {
      handler = (call) {
        throw PlatformException(
          code: 'TOTALLY_UNEXPECTED',
          message: 'mystery error',
        );
      };

      try {
        await provider().authenticate(challenge: bytes(<int>[1]));
        fail('expected WebAuthnAuthenticationFailed');
      } on WebAuthnAuthenticationFailed catch (e) {
        expect(e.message, contains('TOTALLY_UNEXPECTED'));
      }
    });
  });

  group('register null result', () {
    test('null native registration result throws WebAuthnRegistrationFailed',
        () async {
      handler = (call) => null;

      try {
        await provider().register(
          challenge: bytes(<int>[1]),
          userId: bytes(<int>[2]),
          userName: 'alice',
        );
        fail('expected WebAuthnRegistrationFailed');
      } on WebAuthnRegistrationFailed catch (e) {
        expect(e.message, contains('null'));
      }
    });
  });

  group('platform exception WEBAUTHN_NOT_SUPPORTED', () {
    test('register not-supported code wraps as WebAuthnNotSupported', () async {
      handler = (call) {
        throw PlatformException(
          code: 'WEBAUTHN_NOT_SUPPORTED',
          message: 'WebAuthn not available',
        );
      };

      try {
        await provider().register(
          challenge: bytes(<int>[1]),
          userId: bytes(<int>[2]),
          userName: 'alice',
        );
        fail('expected WebAuthnNotSupported');
      } on WebAuthnNotSupported catch (e) {
        expect(e.message, contains('WebAuthn'));
        expect(e.cause, isA<PlatformException>());
      }
    });

    test('authenticate not-supported code wraps as WebAuthnNotSupported',
        () async {
      handler = (call) {
        throw PlatformException(
          code: 'WEBAUTHN_NOT_SUPPORTED',
          message: 'WebAuthn not available on this device',
        );
      };

      try {
        await provider().authenticate(challenge: bytes(<int>[1]));
        fail('expected WebAuthnNotSupported');
      } on WebAuthnNotSupported catch (e) {
        expect(e.message, contains('WebAuthn'));
        expect(e.cause, isA<PlatformException>());
      }
    });
  });

  group('_requireBytes field types', () {
    // These tests exercise the List<int> and generic List paths inside
    // _requireBytes (lines 279-281) and the missing-field throw (line 283),
    // plus _missingBytesException (lines 286, 293-296, 298).

    test('registration result with List<int> bytes is accepted', () async {
      // Return a map where credentialId is List<int>, not Uint8List.
      // The _requireBytes helper falls through to the List<int> branch.
      handler = (call) => <Object?, Object?>{
            'credentialId': <int>[0x01, 0x02, 0x03],
            'publicKey': bytes(List<int>.generate(65, (i) => i & 0xff)),
            'attestationObject': bytes(<int>[0xb0, 0xb1]),
          };

      final result = await provider().register(
        challenge: bytes(<int>[1]),
        userId: bytes(<int>[2]),
        userName: 'alice',
      );
      expect(result.credentialId, bytes(<int>[0x01, 0x02, 0x03]));
    });

    test('registration result with missing credentialId throws registration failed',
        () async {
      // Return a map without credentialId so _requireBytes throws
      // _missingBytesException with registration context.
      handler = (call) => <Object?, Object?>{
            'publicKey': bytes(List<int>.generate(65, (i) => i & 0xff)),
            'attestationObject': bytes(<int>[0xb0, 0xb1]),
          };

      try {
        await provider().register(
          challenge: bytes(<int>[1]),
          userId: bytes(<int>[2]),
          userName: 'alice',
        );
        fail('expected WebAuthnRegistrationFailed');
      } on WebAuthnRegistrationFailed catch (e) {
        expect(e.message, contains('credentialId'));
      }
    });

    test('authentication result with missing credentialId throws authentication failed',
        () async {
      // Return a map without credentialId so _requireBytes throws
      // _missingBytesException with authentication context.
      handler = (call) => <Object?, Object?>{
            'authenticatorData': bytes(<int>[0xd0, 0xd1]),
            'clientDataJSON': bytes(<int>[0xe0, 0xe1]),
            'signature': bytes(<int>[0xf0, 0xf1]),
          };

      try {
        await provider().authenticate(challenge: bytes(<int>[1]));
        fail('expected WebAuthnAuthenticationFailed');
      } on WebAuthnAuthenticationFailed catch (e) {
        expect(e.message, contains('credentialId'));
      }
    });
  });
}
