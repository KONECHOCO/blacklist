import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/spam_number.dart';
import '../models/call_log_item.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  // In-Memory Storage per Web / Desktop Fallback
  final List<SpamNumber> _webSpamList = [];
  final List<CallLogItem> _webCallLogs = [];
  final List<Map<String, dynamic>> _webCustomRules = [];

  DatabaseService._internal() {
    if (kIsWeb) {
      _seedWebData();
    }
  }

  void _seedWebData() {
    _webSpamList.addAll([
      SpamNumber(
        phoneNumber: '+39029475011',
        countryCode: '+39',
        category: SpamCategory.trading,
        reportsCount: 142,
        trustScore: 4.9,
        description: 'Trading online aggressivo, finto broker Londra',
        lastReportedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      SpamNumber(
        phoneNumber: '+39068932091',
        countryCode: '+39',
        category: SpamCategory.telemarketing,
        reportsCount: 98,
        trustScore: 4.8,
        description: 'Operatore energia e gas, luce in scadenza finta',
        lastReportedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      SpamNumber(
        phoneNumber: '+39081192831',
        countryCode: '+39',
        category: SpamCategory.scam,
        reportsCount: 230,
        trustScore: 5.0,
        description: 'Truffa SMS / chiamata finto SMS poste con link malevolo',
        lastReportedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SpamNumber(
        phoneNumber: '+39011948201',
        countryCode: '+39',
        category: SpamCategory.aggressiveSales,
        reportsCount: 54,
        trustScore: 4.2,
        description: 'Promozione telefonia fissa e fibra non richiesta',
        lastReportedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ]);

    _webCallLogs.addAll([
      CallLogItem(
        id: '1',
        phoneNumber: '+39029475011',
        callerName: 'Probabile Trading Online',
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        callType: CallType.blocked,
        isSpam: true,
        spamCategory: SpamCategory.trading,
        spamDescription: 'Trading online aggressivo',
      ),
      CallLogItem(
        id: '2',
        phoneNumber: '+393401234567',
        callerName: 'Marco Rossi (Amico)',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        callType: CallType.incoming,
        isSpam: false,
      ),
      CallLogItem(
        id: '3',
        phoneNumber: '+39068932091',
        callerName: 'Telemarketing Energia',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        callType: CallType.blocked,
        isSpam: true,
        spamCategory: SpamCategory.telemarketing,
        spamDescription: 'Luce e gas in scadenza',
      ),
    ]);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'blacklist_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE spam_numbers (
            phone_number TEXT PRIMARY KEY,
            country_code TEXT NOT NULL,
            category TEXT NOT NULL,
            reports_count INTEGER DEFAULT 1,
            trust_score REAL DEFAULT 1.0,
            description TEXT,
            last_reported_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE call_logs (
            id TEXT PRIMARY KEY,
            phone_number TEXT NOT NULL,
            caller_name TEXT,
            timestamp TEXT NOT NULL,
            call_type TEXT NOT NULL,
            is_spam INTEGER DEFAULT 0,
            spam_category TEXT,
            spam_description TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE custom_blacklist (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pattern TEXT NOT NULL,
            description TEXT,
            created_at TEXT
          )
        ''');

        await _seedInitialData(db);
      },
    );
  }

  Future<void> _seedInitialData(Database db) async {
    final initialSpam = [
      SpamNumber(
        phoneNumber: '+39029475011',
        countryCode: '+39',
        category: SpamCategory.trading,
        reportsCount: 142,
        trustScore: 4.9,
        description: 'Trading online aggressivo, finto broker Londra',
        lastReportedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      SpamNumber(
        phoneNumber: '+39068932091',
        countryCode: '+39',
        category: SpamCategory.telemarketing,
        reportsCount: 98,
        trustScore: 4.8,
        description: 'Operatore energia e gas, luce in scadenza finta',
        lastReportedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

    for (var item in initialSpam) {
      await db.insert('spam_numbers', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // --- Operazioni Spam Numbers ---
  Future<List<SpamNumber>> getAllSpamNumbers() async {
    if (kIsWeb) return List.from(_webSpamList);
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'spam_numbers',
      orderBy: 'last_reported_at DESC',
    );
    return maps.map((map) => SpamNumber.fromMap(map)).toList();
  }

  Future<SpamNumber?> checkNumberSpam(String rawNumber) async {
    final sanitized = rawNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (kIsWeb) {
      try {
        return _webSpamList.firstWhere((element) => element.phoneNumber.contains(sanitized));
      } catch (_) {
        return null;
      }
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'spam_numbers',
      where: 'phone_number LIKE ?',
      whereArgs: ['%$sanitized%'],
    );
    if (maps.isNotEmpty) {
      return SpamNumber.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveSpamReport(SpamNumber spamNumber) async {
    if (kIsWeb) {
      _webSpamList.removeWhere((e) => e.phoneNumber == spamNumber.phoneNumber);
      _webSpamList.insert(0, spamNumber);
      return;
    }
    final db = await database;
    await db.insert(
      'spam_numbers',
      spamNumber.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Operazioni Call Logs ---
  Future<List<CallLogItem>> getCallLogs() async {
    if (kIsWeb) return List.from(_webCallLogs);
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'call_logs',
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => CallLogItem.fromMap(map)).toList();
  }

  Future<void> addCallLog(CallLogItem log) async {
    if (kIsWeb) {
      _webCallLogs.removeWhere((e) => e.id == log.id);
      _webCallLogs.insert(0, log);
      return;
    }
    final db = await database;
    await db.insert('call_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Operazioni Blacklist Personale ---
  Future<List<Map<String, dynamic>>> getCustomBlacklist() async {
    if (kIsWeb) return List.from(_webCustomRules);
    final db = await database;
    return await db.query('custom_blacklist', orderBy: 'id DESC');
  }

  Future<void> addCustomRule(String pattern, String description) async {
    if (kIsWeb) {
      _webCustomRules.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch,
        'pattern': pattern,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });
      return;
    }
    final db = await database;
    await db.insert('custom_blacklist', {
      'pattern': pattern,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteCustomRule(int id) async {
    if (kIsWeb) {
      _webCustomRules.removeWhere((e) => e['id'] == id);
      return;
    }
    final db = await database;
    await db.delete('custom_blacklist', where: 'id = ?', whereArgs: [id]);
  }
}
