import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/spam_number.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();

  ApiService._internal();

  /// Invia la segnalazione 1-Tap al server remoto crowdsourced
  Future<bool> submitSpamReport({
    required String phoneNumber,
    required String countryCode,
    required SpamCategory category,
    required String description,
  }) async {
    try {
      // Simula chiamata API di rete verso il backend Cloud (Supabase / REST Server)
      await Future.delayed(const Duration(milliseconds: 600));
      debugPrint('API Report inviato con successo per $phoneNumber in $countryCode');
      return true;
    } catch (e) {
      debugPrint('Errore durante invio report API: $e');
      return false;
    }
  }

  /// Scarica il pacchetto del database regionale per il Paese selezionato (+39, +1, +44, ecc.)
  Future<List<SpamNumber>> fetchRegionalSpamDatabase(String dialCode) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      // Dati demo scaricati dal cloud per la regione
      return [
        SpamNumber(
          phoneNumber: '$dialCode 028471029',
          countryCode: dialCode,
          category: SpamCategory.telemarketing,
          reportsCount: 310,
          trustScore: 4.9,
          description: 'Call center aggressivo luce e gas',
          lastReportedAt: DateTime.now(),
        ),
        SpamNumber(
          phoneNumber: '$dialCode 069382104',
          countryCode: dialCode,
          category: SpamCategory.trading,
          reportsCount: 180,
          trustScore: 4.8,
          description: 'Truffa finanziaria finto broker',
          lastReportedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        SpamNumber(
          phoneNumber: '$dialCode 011839201',
          countryCode: dialCode,
          category: SpamCategory.scam,
          reportsCount: 420,
          trustScore: 5.0,
          description: 'Finta banca conto bloccato phishing',
          lastReportedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
    } catch (e) {
      debugPrint('Errore fetch DB regionale: $e');
      return [];
    }
  }
}
