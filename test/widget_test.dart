import 'package:blacklist/l10n.dart';
import 'package:blacklist/services/app_state.dart';
import 'package:blacklist/services/phone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every language has every English key and placeholder', () {
    final en = L10n.forCode('en');
    final keys = RegExp(r"'([a-z_]+)':").allMatches(_englishKeysProbe(en)).map((m) => m.group(1)!).toSet();
    expect(keys, isNotEmpty);
    for (final code in L10n.languages.keys) {
      final t = L10n.forCode(code);
      for (final key in keys) {
        final value = t.s(key);
        expect(t.translates(key), isTrue, reason: '$code.$key missing');
        for (final ph in RegExp(r'\{\w+\}').allMatches(en.s(key))) {
          expect(value, contains(ph.group(0)), reason: '$code.$key lacks ${ph.group(0)}');
        }
      }
      for (final c in categories) {
        expect(t.translates('cat_$c'), isTrue, reason: '$code category $c');
      }
    }
  });

  test('unknown language falls back to English', () {
    expect(L10n.forCode('xx').code, 'en');
    expect(L10n.forCode(null).s('tab_lookup'), 'Lookup');
  });

  test('phone numbers normalize to E.164', () {
    expect(Phone.normalize('02 1234 5678', 'IT'), '+390212345678');
    expect(Phone.normalize('+33 1 23 45 67 89', 'IT'), '+33123456789');
    expect(Phone.normalize('abc', 'IT'), isNull);
    expect(Phone.dialCode('IT'), '39');
  });
}

/// Keys used by the UI, listed once here so a missing translation fails the test.
String _englishKeysProbe(L10n en) => const [
      'tab_protection', 'tab_lookup', 'tab_lists', 'tab_settings', 'status_on', 'status_on_body', 'status_off',
      'status_off_android', 'status_off_ios', 'activate', 'ios_steps', 'open_settings', 'country', 'db_numbers',
      'db_updated', 'db_never', 'update_now', 'sync_error', 'community_note', 'mode_title', 'mode_block', 'mode_silence',
      'mode_warn', 'mode_block_desc', 'mode_silence_desc', 'mode_warn_desc', 'opt_hidden', 'opt_hidden_desc',
      'opt_foreign', 'opt_foreign_desc', 'opt_unknown', 'opt_unknown_desc', 'ios_tip_title', 'ios_tip_body',
      'recent_calls', 'no_calls', 'act_block', 'act_silence', 'act_warn', 'act_allow', 'act_unknown', 'report_number',
      'report_title', 'number_hint', 'paste', 'category_label', 'comment_hint', 'send_report', 'report_sent',
      'report_offline', 'invalid_number', 'lookup_hint', 'search', 'verdict_spam', 'verdict_suspicious', 'verdict_clean',
      'reports_count', 'score', 'comments', 'block', 'unblock', 'allow', 'report', 'trending', 'lookup_error',
      'blocked_by_you', 'allowed_by_you', 'lists_blocked', 'lists_ranges', 'lists_allowed', 'add', 'empty_blocked',
      'empty_ranges', 'empty_allowed', 'range_hint', 'range_invalid', 'remove', 'language', 'language_system',
      'ads_title', 'remove_ads', 'restore', 'ad_free', 'purchase_failed', 'nothing_to_restore', 'purchase_unavailable',
      'privacy', 'removal_request', 'support', 'how_title', 'how_body', 'spam', 'version', 'notif_blocked',
      'notif_silenced', 'notif_warn', 'notif_unknown', 'hidden_number', 'notif_user_rule',
    ].map((k) => "'$k':").join(' ');
