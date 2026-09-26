import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';
import '../demo.dart';
import '../l10n.dart';
import 'api.dart';
import 'native.dart';
import 'phone.dart';

/// How the community list is applied to incoming calls.
enum Mode { block, silence, warn }

const categories = ['telemarketing', 'scam', 'trading', 'survey', 'debt', 'sales', 'robocall', 'silent', 'other'];

class ScreenedCall {
  ScreenedCall(this.json);
  final Map<String, dynamic> json;
  String get number => json['n'] as String? ?? '';
  DateTime get at => DateTime.fromMillisecondsSinceEpoch((json['t'] as num?)?.toInt() ?? 0);
  String get action => json['a'] as String? ?? 'unknown';
  String get category => json['c'] as String? ?? '';
  int get score => (json['s'] as num?)?.toInt() ?? 0;
}

/// All app state: settings, the user's own lists, the country's community list,
/// and pushing the resulting rules to the phone (Android service / iOS CallKit).
class AppState extends ChangeNotifier {
  AppState._();
  static final instance = AppState._();

  late SharedPreferences _prefs;
  late File _listFile;

  String install = '';
  String country = 'IT';
  String? language; // null = follow the device
  Mode mode = Mode.block;
  bool blockHidden = false;
  bool blockForeign = false;
  bool askUnknown = true;
  final Map<String, String> blocked = {}; // e164 -> note
  final Set<String> allowed = {};
  final Set<String> ranges = {}; // "+39021234****" patterns
  final Set<String> reported = {};

  List<List<dynamic>> community = []; // [e164, category, score]
  String? _etag;
  int listUpdatedAt = 0;
  Map<String, dynamic>? stats;
  bool active = false;
  bool syncing = false;
  String? syncError;
  List<ScreenedCall> log = [];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (screenshotMode) return _seedDemo();
    _listFile = File('${(await getApplicationSupportDirectory()).path}/community.json');
    install = _prefs.getString('install') ?? _newInstallId();
    await _prefs.setString('install', install);
    country = _prefs.getString('country') ?? _deviceCountry();
    language = _prefs.getString('language');
    mode = Mode.values.firstWhere((m) => m.name == _prefs.getString('mode'), orElse: () => Mode.block);
    blockHidden = _prefs.getBool('blockHidden') ?? false;
    blockForeign = _prefs.getBool('blockForeign') ?? false;
    askUnknown = _prefs.getBool('askUnknown') ?? true;
    blocked.addAll((jsonDecode(_prefs.getString('blocked') ?? '{}') as Map).cast<String, String>());
    allowed.addAll((_prefs.getStringList('allowed') ?? []));
    ranges.addAll((_prefs.getStringList('ranges') ?? []));
    reported.addAll((_prefs.getStringList('reported') ?? []));
    try {
      final cached = jsonDecode(await _listFile.readAsString()) as Map<String, dynamic>;
      if (cached['country'] == country) {
        community = (cached['numbers'] as List).map((r) => (r as List).cast<dynamic>()).toList();
        _etag = cached['etag'] as String?;
        listUpdatedAt = (cached['at'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    notifyListeners();
  }

  void _seedDemo() {
    install = 'screenshots';
    country = Demo.country;
    language = Demo.lang;
    community = Demo.community();
    listUpdatedAt = DateTime.now().subtract(const Duration(minutes: 12)).millisecondsSinceEpoch;
    stats = Demo.stats();
    for (var i = 5; i < 9; i++) {
      blocked[Demo.number(i)] = categories[i % 4];
    }
    ranges.add('${Demo.number(9).substring(0, Demo.number(9).length - 4)}****');
    allowed.add(Demo.number(12));
    active = true;
    notifyListeners();
  }

  String _newInstallId() {
    final r = Random.secure();
    return List.generate(24, (_) => r.nextInt(36).toRadixString(36)).join();
  }

  String _deviceCountry() {
    final code = PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
    return code != null && Phone.iso(code) != null ? code : 'IT';
  }

  // ----------------------------------------------------------------- sync
  /// Downloads the country's community list (only if changed) and re-applies the rules.
  Future<void> sync({bool force = false}) async {
    if (syncing || screenshotMode) return;
    syncing = true;
    syncError = null;
    notifyListeners();
    try {
      final list = await Api.instance.countryList(country, etag: force ? null : _etag);
      if (list != null) {
        community = list.numbers;
        _etag = list.etag;
      }
      listUpdatedAt = DateTime.now().millisecondsSinceEpoch;
      await _listFile.writeAsString(jsonEncode({'country': country, 'etag': _etag, 'at': listUpdatedAt, 'numbers': community}));
      stats = await Api.instance.stats(country);
    } catch (error) {
      syncError = '$error';
    } finally {
      syncing = false;
      await apply();
      notifyListeners();
    }
  }

  bool get needsSync => DateTime.now().millisecondsSinceEpoch - listUpdatedAt > const Duration(hours: 6).inMilliseconds;

  Future<void> refreshStatus() async {
    if (screenshotMode) return;
    active = await Native.instance.isActive();
    final raw = await Native.instance.readLog();
    log = raw
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map((l) {
          try {
            return ScreenedCall(jsonDecode(l) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<ScreenedCall>()
        .toList()
        .reversed
        .toList();
    notifyListeners();
  }

  // ------------------------------------------------------ rules to native
  Future<void> apply() async {
    if (screenshotMode) return;
    final t = L10n.forCode(language ?? PlatformDispatcher.instance.locale.languageCode);
    if (Native.instance.isAndroid) {
      final spam = <String, List<Object>>{};
      for (final row in community) {
        spam[row[0] as String] = [row[1] as String? ?? 'other', (row[2] as num).toInt()];
      }
      await Native.instance.writeRules(jsonEncode({
        'home': country,
        'homeDial': Phone.dialCode(country),
        'mode': mode.name,
        'blockThreshold': 7,
        'blockHidden': blockHidden,
        'blockForeign': blockForeign,
        'askUnknown': askUnknown,
        'allow': allowed.toList(),
        'block': blocked.keys.toList(),
        'prefixes': ranges.map((r) => r.replaceAll('*', '')).toList(),
        'spam': spam,
        'labels': {for (final c in categories) c: t.category(c)},
        'texts': {
          'blocked': t.s('notif_blocked'),
          'silenced': t.s('notif_silenced'),
          'warn': t.s('notif_warn'),
          'unknown': t.s('notif_unknown'),
          'hidden': t.s('hidden_number'),
          'userRule': t.s('notif_user_rule'),
        },
      }));
    } else if (Native.instance.isIOS) {
      // CallKit: digits only, strictly ascending. Block = user list, expanded
      // ranges and (in block mode) community numbers; the rest gets a label.
      final block = <int, String>{};
      final identify = <int, String>{};
      int? digits(String e164) => int.tryParse(e164.replaceAll(RegExp(r'\D'), ''));
      for (final n in blocked.keys) {
        final d = digits(n);
        if (d != null) block[d] = '';
      }
      for (final range in ranges) {
        final stars = '*'.allMatches(range).length;
        final base = range.replaceAll('*', '');
        if (stars == 0 || stars > 4) continue;
        final start = int.tryParse('${base.replaceAll(RegExp(r'\D'), '')}${'0' * stars}');
        if (start == null) continue;
        for (var i = 0; i < pow(10, stars); i++) {
          block[start + i] = '';
        }
      }
      for (final row in community) {
        final d = digits(row[0] as String);
        if (d == null || block.containsKey(d)) continue;
        final score = (row[2] as num).toInt();
        final label = '⚠ ${t.s('spam')}: ${t.category(row[1] as String? ?? 'other')} ($score/9)';
        if (mode == Mode.block && score >= 7) {
          block[d] = '';
        } else {
          identify[d] = label;
        }
      }
      for (final n in allowed) {
        final d = digits(n);
        block.remove(d);
        identify.remove(d);
      }
      String lines(Map<int, String> m) =>
          (m.keys.toList()..sort()).map((k) => m[k]!.isEmpty ? '$k' : '$k\t${m[k]}').join('\n');
      await Native.instance.writeCallDirectory(block: lines(block), identify: lines(identify));
    }
  }

  // ------------------------------------------------------------ settings
  Future<void> setCountry(String value) async {
    if (value == country) return;
    country = value;
    community = [];
    _etag = null;
    listUpdatedAt = 0;
    stats = null;
    await _prefs.setString('country', value);
    notifyListeners();
    await sync(force: true);
  }

  Future<void> setLanguage(String? value) async {
    language = value;
    if (value == null) {
      await _prefs.remove('language');
    } else {
      await _prefs.setString('language', value);
    }
    notifyListeners();
    await apply();
  }

  Future<void> setMode(Mode value) async {
    mode = value;
    await _prefs.setString('mode', value.name);
    notifyListeners();
    await apply();
  }

  Future<void> setFlag(String key, bool value) async {
    switch (key) {
      case 'blockHidden':
        blockHidden = value;
      case 'blockForeign':
        blockForeign = value;
      case 'askUnknown':
        askUnknown = value;
    }
    await _prefs.setBool(key, value);
    notifyListeners();
    await apply();
  }

  // --------------------------------------------------------------- lists
  Future<void> block(String e164, {String note = ''}) async {
    blocked[e164] = note;
    allowed.remove(e164);
    await _saveLists();
  }

  Future<void> unblock(String e164) async {
    blocked.remove(e164);
    await _saveLists();
  }

  Future<void> allow(String e164) async {
    allowed.add(e164);
    blocked.remove(e164);
    await _saveLists();
  }

  Future<void> disallow(String e164) async {
    allowed.remove(e164);
    await _saveLists();
  }

  /// [pattern] like "+39 02 1234 ****" (trailing stars = any digit).
  Future<bool> addRange(String pattern) async {
    final compact = pattern.replaceAll(RegExp(r'[^\d+*]'), '');
    if (!RegExp(r'^\+\d{4,}\*{1,4}$').hasMatch(compact)) return false;
    ranges.add(compact);
    await _saveLists();
    return true;
  }

  Future<void> removeRange(String pattern) async {
    ranges.remove(pattern);
    await _saveLists();
  }

  Future<void> _saveLists() async {
    await _prefs.setString('blocked', jsonEncode(blocked));
    await _prefs.setStringList('allowed', allowed.toList());
    await _prefs.setStringList('ranges', ranges.toList());
    await _prefs.setStringList('reported', reported.toList());
    notifyListeners();
    await apply();
  }

  // -------------------------------------------------------------- report
  /// Sends a community report and blocks the number on this phone right away.
  Future<bool> report(String e164, String category, String comment) async {
    var sent = false;
    try {
      sent = await Api.instance.report(number: e164, region: country, category: category, comment: comment, install: install);
    } catch (_) {}
    reported.add(e164);
    await block(e164, note: category);
    return sent;
  }

  /// Community verdict for a number from the downloaded list (offline).
  List<dynamic>? communityEntry(String e164) {
    for (final row in community) {
      if (row[0] == e164) return row;
    }
    return null;
  }
}
