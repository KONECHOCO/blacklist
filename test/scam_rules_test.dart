import 'dart:convert';

import 'package:blacklist/l10n_messages.dart';
import 'package:blacklist/services/scam_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fake courier SMS is a scam in several languages', () {
    for (final sms in [
      'Poste Italiane: il tuo pacco è in giacenza. Paga 1,99 € entro 24 ore: https://bit.ly/3pAcco',
      'USPS: your package is on hold. Update your address within 24 hours: https://usps-redelivery.top/track',
      'DHL: Ihr Paket konnte nicht zugestellt werden. Zollgebühr sofort zahlen: https://dhl-zustellung.xyz/paket',
      'Correos: su paquete está retenido en aduana. Pague en 24 horas: https://bit.ly/correos',
      '【佐川急便】お荷物をお届けに上がりましたが不在の為持ち帰りました。至急ご確認ください https://bit.ly/sagawa',
    ]) {
      final check = analyzeMessage(sms);
      expect(check.verdict, 'scam', reason: '$sms -> ${check.signals}');
      expect(check.links, isNotEmpty);
    }
  });

  test('asking for a code is flagged', () {
    final check = analyzeMessage('Banca: per sbloccare il conto comunica il codice OTP che hai ricevuto');
    expect(check.signals, containsAll(['asks_code', 'bank']));
    expect(check.verdict, 'scam');
  });

  test('hi mum scam', () {
    expect(analyzeMessage('Ciao mamma, questo è il mio nuovo numero, il telefono si è rotto').signals, contains('family'));
    expect(analyzeMessage('Hi mum, this is my new number').signals, contains('family'));
  });

  test('normal messages stay clean', () {
    for (final sms in ['Ci vediamo alle 8 al bar?', 'Happy birthday! See you tonight', 'Il dentista ti aspetta martedì alle 15.']) {
      expect(analyzeMessage(sms).verdict, 'ok', reason: sms);
    }
  });

  test('user keywords and reported numbers', () {
    final check = analyzeMessage('Offerta speciale fotovoltaico, chiama il 02 9475 1234', keywords: ['fotovoltaico'], isReported: (n) => n.contains('9475'));
    expect(check.signals, containsAll(['user_keyword', 'known_number']));
    expect(check.reportedNumbers, isNotEmpty);
  });

  test('every language translates every Messages string and every signal', () {
    final en = messagesStrings['en']!;
    for (final s in scamSignals) {
      expect(en.containsKey('sig_${s.id}'), isTrue, reason: s.id);
    }
    for (final entry in messagesStrings.entries) {
      expect(entry.value.keys.toSet(), en.keys.toSet(), reason: entry.key);
      for (final k in en.keys.where((k) => en[k]!.contains('{n}'))) {
        expect(entry.value[k], contains('{n}'), reason: '${entry.key}.$k');
      }
    }
    expect(messagesStrings.length, 16);
  });

  test('iOS payload carries the same rules', () {
    final json = jsonDecode(messageFilterJson(strict: true, keywords: ['x'], spamSenders: ['+39 02 1234'], allowedSenders: [])) as Map;
    expect(json['threshold'], suspiciousScore);
    expect((json['signals'] as List).length, scamSignals.length);
    expect(json['spamSenders'], ['39021234']);
  });
}
