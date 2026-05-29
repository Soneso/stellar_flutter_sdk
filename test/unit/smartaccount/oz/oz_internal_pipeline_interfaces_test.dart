// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_internal_pipeline_interfaces.dart';

void main() {
  group('OZConnectedState equality and hashCode', () {
    test('equalInstances_areEqual', () {
      const a = OZConnectedState(
        credentialId: 'cred-001',
        contractId: 'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM',
      );
      const b = OZConnectedState(
        credentialId: 'cred-001',
        contractId: 'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM',
      );

      expect(a == b, isTrue);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differentCredentialId_notEqual', () {
      const a = OZConnectedState(
        credentialId: 'cred-001',
        contractId: 'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM',
      );
      const b = OZConnectedState(
        credentialId: 'cred-002',
        contractId: 'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM',
      );

      expect(a == b, isFalse);
    });

    test('differentContractId_notEqual', () {
      const a = OZConnectedState(
        credentialId: 'cred-001',
        contractId: 'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM',
      );
      const b = OZConnectedState(
        credentialId: 'cred-001',
        contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
      );

      expect(a == b, isFalse);
    });

    test('differentType_notEqual', () {
      const a = OZConnectedState(
        credentialId: 'cred-001',
        contractId: 'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM',
      );

      expect(a == 'not-a-state', isFalse);
    });

    test('identical_isEqual', () {
      const a = OZConnectedState(
        credentialId: 'cred-001',
        contractId: 'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM',
      );

      expect(a == a, isTrue);
    });
  });
}
