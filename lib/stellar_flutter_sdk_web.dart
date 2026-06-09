import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Web entry point for the Stellar Flutter SDK plugin.
///
/// The SDK's web behavior is implemented entirely in Dart through conditional
/// imports, so registration performs no platform-channel setup. This
/// registrant exists so the package declares web as a supported plugin
/// platform; the Flutter web bootstrap calls [registerWith] during startup.
class StellarFlutterSdkWeb {
  /// Invoked by the generated Flutter web plugin registrant at startup.
  static void registerWith(Registrar registrar) {}
}
