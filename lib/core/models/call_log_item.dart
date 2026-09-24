import 'spam_number.dart';

enum CallType { incoming, missed, blocked }

class CallLogItem {
  final String id;
  final String phoneNumber;
  final String? callerName;
  final DateTime timestamp;
  final CallType callType;
  final bool isSpam;
  final SpamCategory? spamCategory;
  final String? spamDescription;

  CallLogItem({
    required this.id,
    required this.phoneNumber,
    this.callerName,
    required this.timestamp,
    required this.callType,
    required this.isSpam,
    this.spamCategory,
    this.spamDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'caller_name': callerName,
      'timestamp': timestamp.toIso8601String(),
      'call_type': callType.name,
      'is_spam': isSpam ? 1 : 0,
      'spam_category': spamCategory?.name,
      'spam_description': spamDescription,
    };
  }

  factory CallLogItem.fromMap(Map<String, dynamic> map) {
    return CallLogItem(
      id: map['id'] as String,
      phoneNumber: map['phone_number'] as String,
      callerName: map['caller_name'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      callType: CallType.values.firstWhere(
        (e) => e.name == map['call_type'],
        orElse: () => CallType.incoming,
      ),
      isSpam: (map['is_spam'] as int? ?? 0) == 1,
      spamCategory: map['spam_category'] != null
          ? SpamCategory.values.firstWhere(
              (e) => e.name == map['spam_category'],
              orElse: () => SpamCategory.telemarketing,
            )
          : null,
      spamDescription: map['spam_description'] as String?,
    );
  }
}
