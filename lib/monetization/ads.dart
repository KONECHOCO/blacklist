import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../app_config.dart';
import 'premium.dart';

/// Unity Ads: full-screen video at launch and after some lookups.
/// AdMob: bottom banner only, non-personalized (the app never asks to track).
class Ads {
  Ads._();
  static final instance = Ads._();

  static const _launchTimeout = Duration(seconds: 8);
  static const _cooldown = Duration(seconds: 60);
  static const _every = 3;

  bool _unityReady = false;
  bool _interstitialReady = false;
  DateTime? _lastShown;
  int _actions = 0;

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  String get _gameId => Platform.isIOS ? unityGameIdIOS : unityGameIdAndroid;
  String get _placement => Platform.isIOS ? 'Interstitial_iOS' : 'Interstitial_Android';
  String get bannerId => Platform.isIOS ? admobBannerIOS : admobBannerAndroid;

  Future<void> init() async {
    if (!_supported || adsSuppressed) return;
    unawaited(_consent().then((_) => MobileAds.instance.initialize()));
    if (_gameId.isEmpty) return;
    try {
      await UnityAds.init(
        gameId: _gameId,
        testMode: kDebugMode,
        onComplete: () {
          _unityReady = true;
          _load();
        },
        onFailed: (error, message) => debugPrint('Unity init failed: $error $message'),
      );
    } catch (e) {
      debugPrint('Unity init error: $e');
    }
  }

  /// Google UMP consent form (shown only where required, e.g. EEA/UK). Never fatal.
  Future<void> _consent() async {
    final done = Completer<void>();
    void finish([Object? _]) {
      if (!done.isCompleted) done.complete();
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => ConsentForm.loadAndShowConsentFormIfRequired(finish),
        finish,
      );
    } catch (_) {
      finish();
    }
    await done.future.timeout(const Duration(seconds: 20), onTimeout: () {});
  }

  void _load() {
    if (!_unityReady || adsSuppressed) return;
    UnityAds.load(
      placementId: _placement,
      onComplete: (_) => _interstitialReady = true,
      onFailed: (_, error, message) {
        _interstitialReady = false;
        Future.delayed(const Duration(seconds: 30), _load);
      },
    );
  }

  Future<bool> _show() async {
    if (adsSuppressed || !_interstitialReady) return false;
    _interstitialReady = false;
    final done = Completer<bool>();
    void finish(bool shown) {
      _load();
      if (!done.isCompleted) done.complete(shown);
    }

    try {
      await UnityAds.showVideoAd(
        placementId: _placement,
        onComplete: (_) => finish(true),
        onSkipped: (_) => finish(true),
        onFailed: (_, error, message) => finish(false),
      );
    } catch (_) {
      finish(false);
    }
    final shown = await done.future;
    if (shown) _lastShown = DateTime.now();
    return shown;
  }

  /// Full-screen video on every cold start, skipped if not ready in time.
  Future<void> showLaunch() async {
    if (!_supported || adsSuppressed) return;
    final deadline = DateTime.now().add(_launchTimeout);
    while (!_interstitialReady && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    await _show();
  }

  /// Every few lookups, with a minimum gap between full-screen ads.
  Future<void> afterAction() async {
    _actions++;
    if (_actions < _every) return;
    final last = _lastShown;
    if (last != null && DateTime.now().difference(last) < _cooldown) return;
    _actions = 0;
    await _show();
  }
}

/// Adaptive AdMob banner; collapses to nothing when ads are off or not filled.
class BannerSlot extends StatefulWidget {
  const BannerSlot({super.key});

  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ad == null) _load();
  }

  Future<void> _load() async {
    if (adsSuppressed || Ads.instance.bannerId.isEmpty) return;
    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width) ?? AdSize.banner;
    final ad = BannerAd(
      adUnitId: Ads.instance.bannerId,
      size: size,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (_) => mounted ? setState(() => _loaded = true) : null,
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (adsSuppressed || !_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(width: ad.size.width.toDouble(), height: ad.size.height.toDouble(), child: AdWidget(ad: ad));
  }
}
