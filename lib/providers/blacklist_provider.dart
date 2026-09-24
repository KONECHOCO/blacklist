import 'package:flutter/material.dart';
import '../core/services/database_service.dart';

class BlacklistProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _customRules = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get customRules => _customRules;
  bool get isLoading => _isLoading;

  Future<void> loadCustomRules() async {
    _isLoading = true;
    notifyListeners();

    _customRules = await DatabaseService.instance.getCustomBlacklist();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRule(String pattern, String description) async {
    if (pattern.trim().isEmpty) return;
    await DatabaseService.instance.addCustomRule(pattern.trim(), description.trim());
    await loadCustomRules();
  }

  Future<void> deleteRule(int id) async {
    await DatabaseService.instance.deleteCustomRule(id);
    await loadCustomRules();
  }
}
