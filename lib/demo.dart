import 'dart:math';

import 'services/api.dart';

/// Store screenshots only (SCREENSHOT_MODE): believable per-language demo data.
/// Screen and language come from the page URL: ?lang=it&tab=1&sheet=report
class Demo {
  static final query = Uri.base.queryParameters;
  static String get lang => query['lang'] ?? 'en';
  static int get tab => int.tryParse(query['tab'] ?? '') ?? 0;
  static bool get reportSheet => query['sheet'] == 'report';
  static int get listTab => int.tryParse(query['list'] ?? '') ?? 0;

  static const _countries = {
    'it': 'IT', 'en': 'US', 'fr': 'FR', 'de': 'DE', 'es': 'ES', 'pt': 'PT', 'nl': 'NL', 'pl': 'PL',
    'ro': 'RO', 'sv': 'SE', 'ru': 'RU', 'uk': 'UA', 'tr': 'TR', 'ar': 'SA', 'zh': 'CN', 'ja': 'JP',
  };

  /// A valid number in each country's format; [number] varies the last two digits.
  static const _numbers = {
    'IT': '+390294751234', 'US': '+12125550147', 'FR': '+33187654321', 'DE': '+493012345678',
    'ES': '+34912345678', 'PT': '+351211234567', 'NL': '+31201234567', 'PL': '+48221234567',
    'RO': '+40211234567', 'SE': '+46812345678', 'RU': '+74951234567', 'UA': '+380441234567',
    'TR': '+902121234567', 'SA': '+966112345678', 'CN': '+861012345678', 'JP': '+81312345678',
  };

  static String get country => _countries[lang] ?? 'US';

  static String number(int n) {
    final base = _numbers[country]!;
    return base.substring(0, base.length - 2) + ((47 + n * 13) % 100).toString().padLeft(2, '0');
  }

  static String get lookupNumber => number(0);

  static List<List<dynamic>> community() {
    final r = Random(7);
    const cats = ['telemarketing', 'scam', 'trading', 'survey', 'robocall', 'sales', 'silent', 'debt'];
    return List.generate(14382, (i) => ['+${900000000000 + i}', cats[r.nextInt(cats.length)], 4 + r.nextInt(6)]);
  }

  static NumberInfo lookup() {
    final c = _comments[lang] ?? _comments['en']!;
    return NumberInfo({
      'number': lookupNumber,
      'reports': 47,
      'score': 9,
      'spam': true,
      'category': 'scam',
      'categories': {'scam': 29, 'telemarketing': 12, 'trading': 6},
      'comments': [for (final t in c) {'category': 'scam', 'text': t}],
    });
  }

  static Map<String, dynamic> stats() => {
        'country': country,
        'spamNumbers': 14382,
        'reportsThisWeek': 2917,
        'trending': [
          for (var i = 1; i <= 4; i++) {'number': number(i), 'reports': 38 - i * 6, 'score': 9 - (i ~/ 2)},
        ],
      };

  static String get reportComment => (_comments[lang] ?? _comments['en']!).last;

  static const _comments = {
    'it': ['Si spacciano per la banca e chiedono il codice OTP. Truffa!', 'Offerta luce e gas, richiamano ogni giorno.'],
    'en': ['Claims to be your bank and asks for the one-time code. Scam!', 'Fake car warranty robocall, calls every day.'],
    'fr': ['Se fait passer pour la banque et demande le code SMS. Arnaque !', 'Démarchage isolation à 1 €, appelle tous les jours.'],
    'de': ['Gibt sich als Bank aus und will die TAN. Betrug!', 'Stromanbieter-Werbung, ruft täglich an.'],
    'es': ['Dicen ser del banco y piden el código SMS. ¡Estafa!', 'Ofertas de luz y gas, llaman cada día.'],
    'pt': ['Dizem ser do banco e pedem o código SMS. Burla!', 'Promoções de eletricidade, ligam todos os dias.'],
    'nl': ['Doet zich voor als de bank en vraagt de sms-code. Oplichting!', 'Energiecontract-verkoop, belt elke dag.'],
    'pl': ['Podszywają się pod bank i proszą o kod SMS. Oszustwo!', 'Oferta fotowoltaiki, dzwonią codziennie.'],
    'ro': ['Se dau drept banca și cer codul SMS. Înșelătorie!', 'Oferte de energie, sună în fiecare zi.'],
    'sv': ['Utger sig för att vara banken och ber om BankID. Bedrägeri!', 'Elavtal-försäljning, ringer varje dag.'],
    'ru': ['Представляются службой безопасности банка и просят код из СМС. Мошенники!', 'Предлагают кредит, звонят каждый день.'],
    'uk': ['Представляються банком і просять код з СМС. Шахраї!', 'Пропонують кредит, дзвонять щодня.'],
    'tr': ['Banka gibi davranıp SMS kodunu istiyorlar. Dolandırıcı!', 'Kredi kartı kampanyası, her gün arıyorlar.'],
    'ar': ['يدّعون أنهم من البنك ويطلبون رمز التحقق. احتيال!', 'عروض تسويقية، يتصلون كل يوم.'],
    'zh': ['冒充银行客服索要验证码，是诈骗！', '推销贷款，每天都打来。'],
    'ja': ['銀行を名乗って認証コードを聞いてくる。詐欺です！', '投資の勧誘、毎日かかってくる。'],
  };
}
