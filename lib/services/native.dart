import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../app_config.dart';

/// Bridge to the platform code (MainActivity.kt / ScreeningBridge.swift).
class Native {
  Native._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'reportNumber' && call.arguments is String) _reportRequests.add(call.arguments as String);
    });
  }
  static final instance = Native._();

  static const _channel = MethodChannel('com.konechoco.blacklist/screening');
  final _reportRequests = StreamController<String>.broadcast();

  /// Numbers the user wants to report from a tapped notification (Android).
  Stream<String> get reportRequests => _reportRequests.stream;

  bool get isIOS => screenshotMode ? screenshotPlatform == 'ios' : Platform.isIOS;
  bool get isAndroid => screenshotMode ? screenshotPlatform == 'android' : Platform.isAndroid;

  Future<bool> isActive() async => screenshotMode || ((await _call<bool>('isActive')) ?? false);

  /// Android: system dialog for the call-screening role. iOS: opens Settings.
  Future<bool> requestActivation() async => (await _call<bool>('requestRole')) ?? false;

  Future<void> writeRules(String json) => _call<Object>('writeRules', {'json': json});

  Future<Object?> writeCallDirectory({required String block, required String identify}) =>
      _call<Object>('writeCallDirectory', {'block': block, 'identify': identify});

  Future<String> readLog() async => (await _call<String>('readLog')) ?? '';

  Future<void> clearLog() => _call<Object>('clearLog');

  Future<String?> takeLaunchNumber() => _call<String>('takeLaunchNumber');

  Future<T?> _call<T>(String method, [Object? args]) async {
    if (screenshotMode) return null;
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
