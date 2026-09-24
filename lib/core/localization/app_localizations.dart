import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('it'));
  }

  static const _localizedValues = <String, Map<String, String>>{
    'it': {
      'app_title': 'Blacklist',
      'shield_active': 'Protezione Chiamate Attiva',
      'shield_inactive': 'Protezione Chiamate Disattivata',
      'shield_desc_active': 'Il tuo telefono è protetto da chiamate pubblicitarie, scam e telemarketing.',
      'shield_desc_inactive': 'Tocca lo scudo per attivare il filtro ed il blocco automatico.',
      'blocked_calls_count': 'Chiamate Bloccate',
      'active_spam_db': 'Numeri in Database',
      'quick_search_hint': 'Cerca un numero di telefono (es. +39...)...',
      'tab_shield': 'Protezione',
      'tab_call_log': 'Storico',
      'tab_blacklist': 'Blacklist',
      'tab_radar': 'Radar Spam',
      'tab_settings': 'Impostazioni',
      'flag_as_spam': 'Segnala come Spam',
      'report_spam_title': 'Aggiungi a Blacklist',
      'report_spam_desc': 'Segnala questo numero per proteggere te stesso e la community.',
      'category_label': 'Categoria di chiamante',
      'description_label': 'Descrizione breve (opzionale)',
      'description_hint': 'Es: Offerta luce e gas aggressiva, chiamano 5 volte al giorno',
      'submit_report': 'Inserisci in Database (1-Tap)',
      'custom_blacklist_title': 'Blacklist Personale',
      'add_custom_rule': 'Aggiungi Numero / Prefisso',
      'prefix_rule_hint': 'Es. +39 02 9475* per bloccare un intero gruppo',
      'premium_banner_title': 'Passa a Blacklist VIP',
      'premium_banner_desc': 'Rimuovi tutte le pubblicità e ricevi aggiornamenti del database auto in background.',
      'upgrade_button': 'Diventa VIP da €1,99/mese',
    },
    'en': {
      'app_title': 'Blacklist',
      'shield_active': 'Call Protection Active',
      'shield_inactive': 'Call Protection Disabled',
      'shield_desc_active': 'Your phone is protected from spam, scam and aggressive sales calls.',
      'shield_desc_inactive': 'Tap the shield to activate call filtering and auto-blocking.',
      'blocked_calls_count': 'Blocked Calls',
      'active_spam_db': 'Numbers in DB',
      'quick_search_hint': 'Search a phone number (e.g. +1...)...',
      'tab_shield': 'Protection',
      'tab_call_log': 'Recents',
      'tab_blacklist': 'Blacklist',
      'tab_radar': 'Spam Radar',
      'tab_settings': 'Settings',
      'flag_as_spam': 'Flag as Spam',
      'report_spam_title': 'Add to Blacklist',
      'report_spam_desc': 'Report this number to protect yourself and the community.',
      'category_label': 'Caller Category',
      'description_label': 'Short description (optional)',
      'description_hint': 'E.g. Aggressive energy sales, calling 5 times a day',
      'submit_report': 'Submit to Database (1-Tap)',
      'custom_blacklist_title': 'Personal Blacklist',
      'add_custom_rule': 'Add Number / Prefix',
      'prefix_rule_hint': 'E.g. +1 800* to block an entire range',
      'premium_banner_title': 'Upgrade to Blacklist VIP',
      'premium_banner_desc': 'Remove all ads and receive automatic background DB updates.',
      'upgrade_button': 'Go VIP from \$1.99/mo',
    },
    'es': {
      'app_title': 'Blacklist',
      'shield_active': 'Protección de Llamadas Activa',
      'shield_inactive': 'Protección Desactivada',
      'shield_desc_active': 'Tu teléfono está protegido contra llamadas spam, estafas y telemarketing.',
      'shield_desc_inactive': 'Toca el escudo para activar el filtro de llamadas.',
      'blocked_calls_count': 'Llamadas Bloqueadas',
      'active_spam_db': 'Números en la Base de Datos',
      'quick_search_hint': 'Buscar un número de teléfono...',
      'tab_shield': 'Protección',
      'tab_call_log': 'Recientes',
      'tab_blacklist': 'Lista Negra',
      'tab_radar': 'Radar Spam',
      'tab_settings': 'Ajustes',
      'flag_as_spam': 'Marcar como Spam',
      'report_spam_title': 'Añadir a la Lista Negra',
      'report_spam_desc': 'Denuncia este número para proteger a toda la comunidad.',
      'category_label': 'Categoría',
      'description_label': 'Descripción breve',
      'description_hint': 'Ej: Venta agresiva, llaman 5 veces al día',
      'submit_report': 'Enviar a la Base de Datos',
      'custom_blacklist_title': 'Lista Negra Personal',
      'add_custom_rule': 'Añadir Número / Prefijo',
      'prefix_rule_hint': 'Ej: +34 91* para bloquear todo el rango',
      'premium_banner_title': 'Hazte VIP en Blacklist',
      'premium_banner_desc': 'Elimina todos los anuncios y recibe actualizaciones automáticas.',
      'upgrade_button': 'Hazte VIP por 1,99 €/mes',
    },
    'de': {
      'app_title': 'Blacklist',
      'shield_active': 'Anrufschutz Aktiviert',
      'shield_inactive': 'Anrufschutz Deaktiviert',
      'shield_desc_active': 'Ihr Telefon ist vor Spam, Betrug und Werbung geschützt.',
      'shield_desc_inactive': 'Tippen Sie auf das Schild, um den Filter zu aktivieren.',
      'blocked_calls_count': 'Blockierte Anrufe',
      'active_spam_db': 'Nummern in der Datenbank',
      'quick_search_hint': 'Telefonnummer suchen...',
      'tab_shield': 'Schutz',
      'tab_call_log': 'Verlauf',
      'tab_blacklist': 'Blacklist',
      'tab_radar': 'Spam Radar',
      'tab_settings': 'Einstellungen',
      'flag_as_spam': 'Als Spam melden',
      'report_spam_title': 'Zur Blacklist hinzufügen',
      'report_spam_desc': 'Melden Sie diese Nummer zum Schutz der Community.',
      'category_label': 'Kategorie',
      'description_label': 'Kurze Beschreibung',
      'description_hint': 'z.B. Aggressive Werbung, rufen mehrmals täglich an',
      'submit_report': 'In Datenbank eintragen (1-Tap)',
      'custom_blacklist_title': 'Eigene Blacklist',
      'add_custom_rule': 'Nummer / Vorwahl hinzufügen',
      'prefix_rule_hint': 'z.B. +49 89* um ganzen Bereich zu blockieren',
      'premium_banner_title': 'Blacklist VIP werden',
      'premium_banner_desc': 'Keine Werbung und automatische Datenbank-Updates im Hintergrund.',
      'upgrade_button': 'VIP werden ab 1,99 €/Monat',
    },
    'fr': {
      'app_title': 'Blacklist',
      'shield_active': 'Protection d\'Appels Active',
      'shield_inactive': 'Protection Désactivée',
      'shield_desc_active': 'Votre téléphone est protégé contre le démarchage et les arnaques.',
      'shield_desc_inactive': 'Appuyez sur le bouclier pour activer le blocage automatique.',
      'blocked_calls_count': 'Appels Bloqués',
      'active_spam_db': 'Numéros dans la Base',
      'quick_search_hint': 'Rechercher un numéro de téléphone...',
      'tab_shield': 'Protection',
      'tab_call_log': 'Récents',
      'tab_blacklist': 'Liste Noire',
      'tab_radar': 'Radar Spam',
      'tab_settings': 'Paramètres',
      'flag_as_spam': 'Signaler comme Spam',
      'report_spam_title': 'Ajouter à la Liste Noire',
      'report_spam_desc': 'Signalez ce numéro pour protéger la communauté.',
      'category_label': 'Catégorie',
      'description_label': 'Description courte',
      'description_hint': 'Ex: Démarchage agressif, appelle 5 fois par jour',
      'submit_report': 'Ajouter à la Base (1-Tap)',
      'custom_blacklist_title': 'Liste Noire Personnelle',
      'add_custom_rule': 'Ajouter Numéro / Préfixe',
      'prefix_rule_hint': 'Ex: +33 1* pour bloquer tout le groupe',
      'premium_banner_title': 'Passez à Blacklist VIP',
      'premium_banner_desc': 'Supprimez toutes les publicités et profitez des mises à jour auto.',
      'upgrade_button': 'Devenir VIP à 1,99 €/mois',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['it', 'en', 'es', 'de', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
