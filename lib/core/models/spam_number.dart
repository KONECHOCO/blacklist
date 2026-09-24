enum SpamCategory {
  telemarketing,
  scam,
  trading,
  survey,
  debtCollector,
  aggressiveSales,
  silentCall,
  other,
}

extension SpamCategoryExtension on SpamCategory {
  String get displayName {
    switch (this) {
      case SpamCategory.telemarketing:
        return 'Telemarketing';
      case SpamCategory.scam:
        return 'Truffa / Scam';
      case SpamCategory.trading:
        return 'Trading Online / Forex';
      case SpamCategory.survey:
        return 'Sondaggi Telefonici';
      case SpamCategory.debtCollector:
        return 'Recupero Crediti Aggressivo';
      case SpamCategory.aggressiveSales:
        return 'Vendita Aggressiva';
      case SpamCategory.silentCall:
        return 'Chiamata Muta / Bot';
      case SpamCategory.other:
        return 'Altro Spam';
    }
  }
}

class SpamNumber {
  final String phoneNumber;
  final String countryCode;
  final SpamCategory category;
  final int reportsCount;
  final double trustScore;
  final String description;
  final DateTime lastReportedAt;

  SpamNumber({
    required this.phoneNumber,
    required this.countryCode,
    required this.category,
    required this.reportsCount,
    required this.trustScore,
    required this.description,
    required this.lastReportedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'category': category.name,
      'reports_count': reportsCount,
      'trust_score': trustScore,
      'description': description,
      'last_reported_at': lastReportedAt.toIso8601String(),
    };
  }

  factory SpamNumber.fromMap(Map<String, dynamic> map) {
    return SpamNumber(
      phoneNumber: map['phone_number'] as String,
      countryCode: map['country_code'] as String? ?? '+39',
      category: SpamCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => SpamCategory.telemarketing,
      ),
      reportsCount: map['reports_count'] as int? ?? 1,
      trustScore: (map['trust_score'] as num?)?.toDouble() ?? 1.0,
      description: map['description'] as String? ?? '',
      lastReportedAt: map['last_reported_at'] != null
          ? DateTime.parse(map['last_reported_at'] as String)
          : DateTime.now(),
    );
  }
}
