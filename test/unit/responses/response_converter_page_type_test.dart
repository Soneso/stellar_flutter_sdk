import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as sdk;

class Page<T> {}

void main() {
  test('ResponseConverter distinguishes page types with identical names', () {
    final unrelatedType = Page<sdk.AccountResponse>;
    final sdkType = sdk.Page<sdk.AccountResponse>;
    expect(unrelatedType, isNot(sdkType));
    expect(unrelatedType.toString(), sdkType.toString());

    final json = <String, dynamic>{
      '_embedded': {'records': <dynamic>[]},
    };
    expect(
      sdk.ResponseConverter.fromJson<sdk.Page<sdk.AccountResponse>>(json),
      isA<sdk.Page<sdk.AccountResponse>>(),
    );
    expect(
      sdk.ResponseConverter.fromJson<Page<sdk.AccountResponse>>(json),
      isNull,
    );
    expect(sdk.ResponseConverter.fromJson<String>(json), isNull);
  });
}
