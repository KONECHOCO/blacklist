import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Phone number helpers. Everything is stored as E.164 (+390212345678).
class Phone {
  /// E.164 for [raw] (any format; national numbers resolved with [home]),
  /// or null when it isn't a plausible phone number.
  static String? normalize(String raw, String home) {
    final cleaned = raw.trim();
    if (cleaned.replaceAll(RegExp(r'\D'), '').length < 5) return null;
    try {
      final parsed = PhoneNumber.parse(cleaned, callerCountry: iso(home));
      if (parsed.nsn.length < 4) return null;
      return parsed.international;
    } catch (_) {
      return null;
    }
  }

  /// Readable form: national format for home-country numbers, international otherwise.
  static String display(String e164, String home) {
    try {
      final parsed = PhoneNumber.parse(e164);
      final nsn = parsed.formatNsn();
      return parsed.isoCode.name == home ? nsn : '+${parsed.countryCode} $nsn';
    } catch (_) {
      return e164;
    }
  }

  static String? countryOf(String e164) {
    try {
      return PhoneNumber.parse(e164).isoCode.name;
    } catch (_) {
      return null;
    }
  }

  static String dialCode(String code) {
    final value = iso(code);
    if (value == null) return '';
    try {
      return PhoneNumber.parse('0', destinationCountry: value).countryCode;
    } catch (_) {
      return '';
    }
  }

  static IsoCode? iso(String code) {
    for (final value in IsoCode.values) {
      if (value.name == code.toUpperCase()) return value;
    }
    return null;
  }
}
