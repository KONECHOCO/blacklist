import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/phone.dart';
import 'theme.dart';

/// Rounded card with an optional small caps title above it.
class Section extends StatelessWidget {
  const Section({super.key, this.title, required this.children, this.padding = EdgeInsets.zero});
  final String? title;
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(title!.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.6)),
            ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(padding: padding, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
          ),
        ],
      ),
    );
  }
}

/// 1–9 score badge: green (no reports), amber (suspicious), red (spam).
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score, this.size = 40});
  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(score);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Text(score == 0 ? '✓' : '$score',
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: size * 0.42)),
    );
  }
}

Color scoreColor(int score) => score >= 7 ? brandRed : (score >= 4 ? warnAmber : safeGreen);

String flag(String country) => country.length != 2
    ? '🌐'
    : String.fromCharCodes(country.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 65));

/// Always left-to-right, also inside Arabic text.
String prettyNumber(String e164, String home) => '\u2066${Phone.display(e164, home)}\u2069';

String relativeTime(BuildContext context, DateTime at) {
  final locale = Localizations.localeOf(context).toString();
  final now = DateTime.now();
  if (now.difference(at).inHours < 20 && now.day == at.day) return DateFormat.Hm(locale).format(at);
  if (now.difference(at).inDays < 6) return DateFormat.E(locale).add_Hm().format(at);
  return DateFormat.yMMMd(locale).format(at);
}

void toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
}

/// Countries offered in the picker (ISO codes); any other one still works via the device region.
const countries = [
  'IT', 'US', 'GB', 'FR', 'DE', 'ES', 'PT', 'NL', 'BE', 'CH', 'AT', 'IE', 'LU', 'PL', 'RO', 'CZ', 'SK', 'HU', 'SI', 'HR',
  'GR', 'BG', 'SE', 'NO', 'DK', 'FI', 'RU', 'UA', 'TR', 'CA', 'MX', 'BR', 'AR', 'CL', 'CO', 'PE', 'AU', 'NZ', 'IN',
  'JP', 'CN', 'HK', 'TW', 'KR', 'SG', 'MY', 'PH', 'ID', 'TH', 'VN', 'AE', 'SA', 'QA', 'KW', 'EG', 'MA', 'DZ', 'TN',
  'ZA', 'NG', 'KE', 'CI', 'SN', 'CM', 'GH', 'IL',
];
