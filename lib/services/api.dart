import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../demo.dart';

class NumberInfo {
  NumberInfo(this.json);
  final Map<String, dynamic> json;

  String get number => json['number'] as String;
  int get reports => (json['reports'] as num?)?.toInt() ?? 0;
  int get score => (json['score'] as num?)?.toInt() ?? 0;
  bool get spam => json['spam'] == true;
  String? get category => json['category'] as String?;
  Map<String, int> get categories =>
      (json['categories'] as Map? ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt()));
  List<Map<String, dynamic>> get comments =>
      (json['comments'] as List? ?? []).map((m) => (m as Map).cast<String, dynamic>()).toList();
}

class CountryList {
  CountryList({required this.numbers, required this.etag, required this.generatedAt});

  /// Rows of [e164, category, score].
  final List<List<dynamic>> numbers;
  final String? etag;
  final int generatedAt;
}

/// Client of the community API (server/ in this repo).
class Api {
  Api._();
  static final instance = Api._();
  final _client = http.Client();
  static const _timeout = Duration(seconds: 12);

  Uri _u(String path, [Map<String, String>? query]) => Uri.parse('$apiBase$path').replace(queryParameters: query);

  Future<bool> report({
    required String number,
    required String region,
    required String category,
    required String comment,
    required String install,
  }) async {
    final r = await _client
        .post(_u('/v1/reports'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'number': number, 'region': region, 'category': category, 'comment': comment, 'install': install}))
        .timeout(_timeout);
    return r.statusCode == 200;
  }

  Future<NumberInfo?> lookup(String number, String region) async {
    if (screenshotMode) return Demo.lookup();
    final r = await _client.get(_u('/v1/lookup', {'number': number, 'region': region})).timeout(_timeout);
    if (r.statusCode != 200) return null;
    return NumberInfo(jsonDecode(r.body) as Map<String, dynamic>);
  }

  /// Reports an offensive comment (hidden for everyone after a few reports).
  Future<void> flagComment(int id, String install) async {
    if (screenshotMode) return;
    await _client
        .post(_u('/v1/comments/flag'), headers: {'content-type': 'application/json'}, body: jsonEncode({'id': id, 'install': install}))
        .timeout(_timeout);
  }

  /// Null when unchanged since [etag] (HTTP 304).
  Future<CountryList?> countryList(String country, {String? etag}) async {
    final r = await _client
        .get(_u('/v1/lists/$country'), headers: {'If-None-Match': ?etag})
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 304) return null;
    if (r.statusCode != 200) throw http.ClientException('HTTP ${r.statusCode}');
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return CountryList(
      numbers: (body['numbers'] as List).map((row) => (row as List).cast<dynamic>()).toList(),
      etag: r.headers['etag'],
      generatedAt: (body['generatedAt'] as num).toInt(),
    );
  }

  Future<Map<String, dynamic>?> stats(String country) async {
    if (screenshotMode) return Demo.stats();
    final r = await _client.get(_u('/v1/stats/$country')).timeout(_timeout);
    if (r.statusCode != 200) return null;
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
