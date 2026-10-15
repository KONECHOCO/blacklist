import 'dart:convert';

/// Offline scam-message rules, shared by the "Check a message" screen and the
/// iOS SMS filter extension (MessageFilter, which gets them as JSON through the
/// App Group). Patterns are case-insensitive regular expressions written to
/// work in both Dart and NSRegularExpression (no look-behind, no \p classes).
class ScamSignal {
  const ScamSignal(this.id, this.weight, this.pattern);
  final String id;
  final int weight;
  final String pattern;
}

const scamSignals = <ScamSignal>[
  // Link shorteners hide where a link really goes.
  ScamSignal('link_short', 3,
      r'(bit\.ly|tinyurl\.com|t\.co/|is\.gd|cutt\.ly|rb\.gy|shorturl\.at|tiny\.cc|ow\.ly|goo\.gl|t\.ly|rebrand\.ly|bl\.ink|qrco\.de|s\.id/|shorturl\.|u\.to/)'),
  // Cheap top-level domains favoured by phishing kits.
  ScamSignal('link_odd', 2,
      r'[a-z0-9-]+\.(xyz|top|click|shop|live|icu|buzz|cfd|sbs|cyou|rest|monster|lol|vip|online|site|link|support|help|info|work|fun|bond|best)(/|\s|$)'),
  ScamSignal('link', 1, r'(https?://|www\.)'),
  // Asking to send, share or read back a code or password.
  ScamSignal('asks_code', 3,
      r'(send|share|reply with|tell us|give|forward|invia|comunica|condividi|inoltra|rispondi con|envoyez|envoie|communiquez|transmettez|sende|teilen|nennen|antworte|envía|envia|comparte|dinos|compartilhe|informe|stuur|deel|geef|wyślij|podaj|przekaż|trimite|spune|comunică|skicka|dela|uppge|отправ|сообщ|назов|продикт|надішл|повідом|назв|gönder|paylaş|söyle|ilet|أرسل|شارك|أخبرنا|发送|告诉|提供|转发|送って|教えて|返信して|伝えて)[^.!?\n]{0,40}(code|codice|código|kod|cod|pin|otp|tan|bankid|password|passwort|mot de passe|contraseña|senha|wachtwoord|hasło|parolă|lösenord|код|пароль|kodu|şifre|رمز|كلمة المرور|验证码|密码|コード|暗証番号|パスワード)'),
  // Pressure and threats: blocked, suspended, last notice, within 24 hours.
  ScamSignal('urgency', 2,
      r'(urgent|immediately|within 24|last warning|final notice|suspended|blocked|locked|deactivated|expire|urgente|subito|immediatamente|entro 24|bloccat|sospes|scadut|disattivat|ultimo avviso|immédiatement|bloqué|suspendu|expiré|dernier avis|dringend|sofort|gesperrt|ausgesetzt|abgelaufen|letzte mahnung|inmediatamente|bloquead|suspendid|caducad|último aviso|imediatamente|suspens|expirad|onmiddellijk|geblokkeerd|opgeschort|verlopen|pilne|natychmiast|zablokowan|zawieszon|wygas|imediat|blocat|suspendat|expirat|brådskande|omedelbart|spärrat|avstängt|срочно|немедленно|заблокир|приостановл|истек|терміново|негайно|заблоков|призупин|acil|hemen|bloke|askıya|süresi dol|عاجل|فوراً|فورا|محظور|موقوف|تعليق|紧急|立即|冻结|停用|过期|至急|直ちに|停止|凍結|期限切れ)'),
  // Fake courier / customs fee.
  ScamSignal('delivery', 2,
      r'(package|parcel|delivery|shipment|customs|courier|dhl|ups|fedex|usps|royal mail|evri|dpd|gls|hermes|inpost|postnl|pacco|spedizione|consegna|corriere|dogana|giacenza|poste italiane|brt|colis|livraison|douane|chronopost|la poste|paket|sendung|zustellung|zoll|paquete|envío|entrega|aduana|correos|encomenda|alfândega|ctt|pakket|bezorging|paczk|przesyłk|dostaw|colet|livrare|vamă|leverans|tull|posten|посылк|доставк|таможн|посилк|митн|нова пошта|kargo|teslimat|gümrük|ptt|طرد|شحنة|توصيل|جمارك|包裹|快递|派送|海关|荷物|配達|不在|税関|宅配)'),
  // Bank, card or account data.
  ScamSignal('bank', 2,
      r'(bank|account|credit card|iban|payment|banca|conto|carta di credito|pagamento|bonifico|banque|compte|carte bancaire|paiement|konto|karte|zahlung|banco|cuenta|tarjeta|pago|conta|cartão|rekening|betaling|karta|płatność|cont bancar|plată|kort|betalning|банк|сч[её]т|карт[ауы]|платеж|рахун|картк|платіж|banka|hesab|ödeme|بنك|حساب|بطاقة|银行|账户|銀行|口座|クレジットカード)'),
  // Prizes, gifts and refunds nobody asked for.
  ScamSignal('prize', 2,
      r'(you won|you have won|winner|prize|gift card|reward|refund|lottery|hai vinto|vincitore|premio|buono regalo|rimborso|vous avez gagné|gagnant|cadeau|remboursement|gewonnen|gewinn|geschenk|erstattung|has ganado|ganador|regalo|reembolso|ganhou|prémio|prêmio|prijs gewonnen|terugbetaling|wygrał|nagrod|zwrot|ai câștigat|premiu|rambursare|du har vunnit|vinst|återbetalning|выиграл|приз|подарок|возврат|виграли|подарун|повернення|kazandınız|ödül|hediye|iade|ربحت|جائزة|هدية|استرداد|中奖|奖品|礼品卡|退款|当選|賞品|ギフト|返金)'),
  // "Hi mum, this is my new number".
  ScamSignal('family', 3,
      r'(hi mum|hi mom|hi dad|new number|my phone broke|ciao mamma|ciao papà|ciao papa|nuovo numero|telefono rotto|coucou maman|salut papa|nouveau numéro|hallo mama|hallo papa|neue nummer|handy (ist )?kaputt|hola mamá|hola papá|nuevo número|olá mãe|oi mãe|olá pai|novo número|hoi mam|hoi pap|nieuw nummer|cześć mamo|cześć tato|nowy numer|bună mamă|bună tată|număr nou|hej mamma|hej pappa|nytt nummer|мама,? это я|новый номер|мамо,? це я|новий номер|anne ben|yeni numaram|مرحبا أمي|رقمي الجديد|妈,? 是我|我换号了|母さん|新しい番号)'),
  // Crypto and "guaranteed" investments.
  ScamSignal('invest', 2,
      r'(crypto|bitcoin|invest|trading|guaranteed return|daily profit|criptovalut|investiment|guadagn|rendimento garantito|investissement|rendement garanti|krypto|investition|rendite|inversión|rentabilidad|lucro garantido|beleggen|rendement|inwestycj|zysk|investiți|investera|крипт|инвест|доходност|інвест|прибуток|kripto|yatırım|kazanç|استثمار|عملات رقمية|أرباح|投资|加密货币|收益|投資|暗号資産|利回り)'),
  // Asked to call back an unknown number.
  ScamSignal('callback', 1,
      r'(call us|call back|call this number|chiama(ci)? (il|al)|richiama|appelez|rappelez|rufen sie|zurückrufen|llame al|llámanos|ligue para|bel ons|bel terug|zadzwoń|sunați|ring oss|позвоните|перезвоните|зателефонуйте|arayın|اتصل ب|致电|回电|お電話ください|折り返し)'),
];

/// Weight of a phone number in the text that the community reported as spam,
/// and of a keyword the user chose to block.
const knownNumberWeight = 3;
const userKeywordWeight = 5;

/// Score thresholds: suspicious from 3, scam from 5. The iOS filter moves a
/// message to Junk from 5 (normal) or from 3 (strict).
const suspiciousScore = 3;
const scamScore = 5;

class ScamCheck {
  ScamCheck({required this.score, required this.signals, required this.links, required this.numbers, required this.reportedNumbers});
  final int score;
  final List<String> signals;
  final List<String> links;
  final List<String> numbers;
  final List<String> reportedNumbers;

  String get verdict => score >= scamScore ? 'scam' : (score >= suspiciousScore ? 'suspicious' : 'ok');
}

final _compiled = {for (final s in scamSignals) s.id: RegExp(s.pattern, caseSensitive: false, unicode: true)};
final _linkRe = RegExp(r'(https?://[^\s]+|www\.[^\s]+|[a-z0-9-]+\.[a-z]{2,}/[^\s]*)', caseSensitive: false);
final _phoneRe = RegExp(r'\+?\d[\d \-./()]{6,16}\d');

/// Analyses a pasted message. [isReported] tells whether a number (as typed
/// in the text) is on the community list; [keywords] are the user's own.
ScamCheck analyzeMessage(String text, {bool Function(String number)? isReported, Iterable<String> keywords = const []}) {
  var score = 0;
  final signals = <String>[];
  for (final s in scamSignals) {
    if (s.id == 'link' && (signals.contains('link_short') || signals.contains('link_odd'))) continue;
    if (_compiled[s.id]!.hasMatch(text)) {
      score += s.weight;
      signals.add(s.id);
    }
  }
  final lower = text.toLowerCase();
  if (keywords.any((k) => k.trim().isNotEmpty && lower.contains(k.trim().toLowerCase()))) {
    score += userKeywordWeight;
    signals.add('user_keyword');
  }
  final numbers = _phoneRe.allMatches(text).map((m) => m.group(0)!.trim()).toSet().toList();
  final reported = isReported == null ? <String>[] : numbers.where(isReported).toList();
  if (reported.isNotEmpty) {
    score += knownNumberWeight;
    signals.add('known_number');
  }
  return ScamCheck(
    score: score,
    signals: signals,
    links: _linkRe.allMatches(text).map((m) => m.group(0)!).toSet().toList(),
    numbers: numbers,
    reportedNumbers: reported,
  );
}

/// Payload for the iOS MessageFilter extension (App Group "sms_filter.json").
String messageFilterJson({required bool strict, required Iterable<String> keywords, required Iterable<String> spamSenders, required Iterable<String> allowedSenders}) =>
    jsonEncode({
      'threshold': strict ? suspiciousScore : scamScore,
      'signals': [for (final s in scamSignals) {'id': s.id, 'weight': s.weight, 'pattern': s.pattern}],
      'keywords': keywords.toList(),
      'keywordWeight': userKeywordWeight,
      'spamSenders': spamSenders.map((n) => n.replaceAll(RegExp(r'\D'), '')).toList(),
      'allowedSenders': allowedSenders.map((n) => n.replaceAll(RegExp(r'\D'), '')).toList(),
    });
