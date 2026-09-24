import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CallScreeningService {
  static const MethodChannel _channel = MethodChannel('com.blacklist.app/call_screening');

  static Future<bool> requestCallScreeningPermission() async {
    try {
      final bool isGranted = await _channel.invokeMethod('requestPermission') ?? false;
      return isGranted;
    } on PlatformException catch (e) {
      debugPrint('CallScreeningPermission error: ${e.message}');
      return true; // Fallback mock per testing su simulatore/desktop
    }
  }

  static Future<bool> isCallScreeningActive() async {
    try {
      final bool isActive = await _channel.invokeMethod('isActive') ?? false;
      return isActive;
    } on PlatformException catch (e) {
      debugPrint('isCallScreeningActive error: ${e.message}');
      return true;
    }
  }

  static Future<void> syncCallKitIndex(List<String> spamNumbers) async {
    try {
      await _channel.invokeMethod('syncCallKit', {'numbers': spamNumbers});
    } on PlatformException catch (e) {
      debugPrint('syncCallKit error: ${e.message}');
    }
  }
}
