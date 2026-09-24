import 'package:flutter/material.dart';
import '../core/models/spam_number.dart';
import '../core/models/call_log_item.dart';
import '../core/services/database_service.dart';
import '../core/services/api_service.dart';

class SpamDatabaseProvider extends ChangeNotifier {
  List<SpamNumber> _spamNumbers = [];
  List<CallLogItem> _callLogs = [];
  bool _isLoading = false;
  SpamNumber? _searchResult;
  bool _isSearching = false;

  List<SpamNumber> get spamNumbers => _spamNumbers;
  List<CallLogItem> get callLogs => _callLogs;
  bool get isLoading => _isLoading;
  SpamNumber? get searchResult => _searchResult;
  bool get isSearching => _isSearching;

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    _spamNumbers = await DatabaseService.instance.getAllSpamNumbers();
    _callLogs = await DatabaseService.instance.getCallLogs();

    _isLoading = false;
    notifyListeners();
  }

  Future<SpamNumber?> searchNumber(String rawNumber) async {
    if (rawNumber.trim().isEmpty) {
      _searchResult = null;
      notifyListeners();
      return null;
    }
    _isSearching = true;
    notifyListeners();

    _searchResult = await DatabaseService.instance.checkNumberSpam(rawNumber);

    _isSearching = false;
    notifyListeners();
    return _searchResult;
  }

  void clearSearch() {
    _searchResult = null;
    notifyListeners();
  }

  /// 1-Tap Spam Report (Utente inserisce un numero con 1 clic nel database)
  Future<bool> reportSpamNumber({
    required String phoneNumber,
    required String countryCode,
    required SpamCategory category,
    required String description,
  }) async {
    _isLoading = true;
    notifyListeners();

    final newSpam = SpamNumber(
      phoneNumber: phoneNumber.replaceAll(' ', ''),
      countryCode: countryCode,
      category: category,
      reportsCount: 1,
      trustScore: 5.0,
      description: description,
      lastReportedAt: DateTime.now(),
    );

    // Salva in DB Locale
    await DatabaseService.instance.saveSpamReport(newSpam);

    // Aggiorna anche l'eventuale chiamata nel registro chiamate come spam
    final newLog = CallLogItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      phoneNumber: phoneNumber,
      timestamp: DateTime.now(),
      callType: CallType.blocked,
      isSpam: true,
      spamCategory: category,
      spamDescription: description,
    );
    await DatabaseService.instance.addCallLog(newLog);

    // Invia al Cloud via ApiService
    await ApiService.instance.submitSpamReport(
      phoneNumber: phoneNumber,
      countryCode: countryCode,
      category: category,
      description: description,
    );

    // Ricarica la lista
    await loadInitialData();

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Sincronizzazione database per zona geografica
  Future<void> syncRegionalDatabase(String dialCode) async {
    _isLoading = true;
    notifyListeners();

    final remoteNumbers = await ApiService.instance.fetchRegionalSpamDatabase(dialCode);
    for (var num in remoteNumbers) {
      await DatabaseService.instance.saveSpamReport(num);
    }

    await loadInitialData();
    _isLoading = false;
    notifyListeners();
  }
}
