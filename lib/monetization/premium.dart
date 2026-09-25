import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';

/// True when no ad may be loaded or shown ("Remove ads" buyers, screenshots).
bool get adsSuppressed => screenshotMode || Premium.instance.adFree;

/// "Remove ads" one-time (non-consumable) purchase — same product scheme as the
/// other KONECHOCO apps (`<bundle>.removeads`, 2.99 EUR).
class Premium extends ChangeNotifier {
  Premium._();
  static final instance = Premium._();

  static const _cacheKey = 'premium.adFree';

  InAppPurchase get _iap => InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  SharedPreferences? _prefs;
  ProductDetails? _product;
  bool _adFree = false;
  bool _busy = false;

  /// Result of the last buy/restore: 'failed', 'notFound', 'unavailable' or null.
  String? outcome;

  bool get adFree => _adFree;
  bool get busy => _busy;
  String? get price => _product?.price;
  bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS) && !screenshotMode;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _adFree = _prefs?.getBool(_cacheKey) ?? false;
    } catch (_) {}
    if (!supported) return;
    _subscription ??= _iap.purchaseStream.listen(_onPurchases, onError: (Object e) => debugPrint('Purchase stream error: $e'));
    unawaited(_loadProduct());
    // Android restores silently; on iOS only from "Restore purchases" (may ask for the Apple ID).
    if (Platform.isAndroid) unawaited(_iap.restorePurchases());
  }

  Future<void> buy() async {
    outcome = null;
    if (_product == null) await _loadProduct();
    final product = _product;
    if (product == null) {
      outcome = 'unavailable';
      notifyListeners();
      return;
    }
    _setBusy(true);
    try {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (_) {
      outcome = 'failed';
      _setBusy(false);
    }
  }

  Future<void> restore() async {
    outcome = null;
    _setBusy(true);
    try {
      await _iap.restorePurchases();
      await Future<void>.delayed(const Duration(seconds: 4));
      if (!_adFree) outcome = 'notFound';
    } catch (_) {
      outcome = 'failed';
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _loadProduct() async {
    try {
      if (!await _iap.isAvailable()) return;
      final response = await _iap.queryProductDetails({removeAdsProductId});
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != removeAdsProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _setAdFree(true);
          _setBusy(false);
        case PurchaseStatus.error:
          outcome = 'failed';
          _setBusy(false);
        case PurchaseStatus.canceled:
          _setBusy(false);
        case PurchaseStatus.pending:
          break;
      }
      if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
    }
  }

  Future<void> _setAdFree(bool value) async {
    if (_adFree == value) return;
    _adFree = value;
    notifyListeners();
    await _prefs?.setBool(_cacheKey, value);
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
