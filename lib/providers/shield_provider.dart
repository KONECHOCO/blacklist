import 'package:flutter/material.dart';
import '../core/models/country_region.dart';
import '../core/services/call_screening_service.dart';

class ShieldProvider extends ChangeNotifier {
  bool _isProtectionActive = true;
  int _blockedCallsCount = 142;
  CountryRegion _selectedRegion = CountryRegion.defaultSupportedRegions.first;
  bool _isLoading = false;

  bool get isProtectionActive => _isProtectionActive;
  int get blockedCallsCount => _blockedCallsCount;
  CountryRegion get selectedRegion => _selectedRegion;
  bool get isLoading => _isLoading;

  Future<void> toggleProtection() async {
    _isLoading = true;
    notifyListeners();

    if (!_isProtectionActive) {
      final isGranted = await CallScreeningService.requestCallScreeningPermission();
      if (isGranted) {
        _isProtectionActive = true;
      }
    } else {
      _isProtectionActive = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSelectedRegion(CountryRegion region) {
    _selectedRegion = region;
    notifyListeners();
  }

  void incrementBlockedCalls() {
    _blockedCallsCount++;
    notifyListeners();
  }
}
