## [Stellar SDK for Flutter](https://github.com/Soneso/stellar_flutter_sdk) Installation

### From pub.dev
1. Add the dependency to your pubspec.yaml file:
```
dependencies:
  stellar_flutter_sdk: ^0.8.0
```
2. Install it (command line or IDE):
```
flutter pub get
```
3. In your source file import the SDK, initialize and use it:
```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final StellarSDK sdk = StellarSDK.TESTNET;

String accountId = "GASYKQXV47TPTB6HKXWZNB6IRVPMTQ6M6B27IM5L2LYMNYBX2O53YJAL";
AccountResponse account = await sdk.accounts.account(accountId);
print("sequence number: ${account.sequenceNumber}");
```
   
### Manual

Add the SDK is a Flutter Dart plugin. Here is a step by step that we recommend:

1. Clone this repo.
2. Open the project in your IDE (e.g. Android Studio).
3. Open the file `pubspec.yaml` and press `Pub get` in your IDE.
4. Go to the project's `test` directory, run a test from there and you are good to go!

Add it to your app:

5. In your Flutter app add the local dependency in `pubspec.yaml` and then run `pub get`:
```code
dependencies:
   flutter:
     sdk: flutter
   stellar_flutter_sdk:
     path: ../stellar_flutter_sdk
```
6. In your source file import the SDK, initialize and use it:
```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final StellarSDK sdk = StellarSDK.TESTNET;

String accountId = "GASYKQXV47TPTB6HKXWZNB6IRVPMTQ6M6B27IM5L2LYMNYBX2O53YJAL";
AccountResponse account = await sdk.accounts.account(accountId);
print("sequence number: ${account.sequenceNumber}");
```
To continue learning about the sdk, please have a look to our [Quick start guide](quick_start.md)
