import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumProvider extends ChangeNotifier {
  bool _isPremium = false;
  String _localeCode = 'it';

  bool get isPremium => _isPremium;
  String get localeCode => _localeCode;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('is_premium') ?? false;
    _localeCode = prefs.getString('locale_code') ?? 'it';
    notifyListeners();
  }

  Future<void> setPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', value);
    notifyListeners();
  }

  Future<void> setLocaleCode(String code) async {
    _localeCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale_code', code);
    notifyListeners();
  }
}
