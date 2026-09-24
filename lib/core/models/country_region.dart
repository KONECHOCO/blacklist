class CountryRegion {
  final String code; // ISO code (e.g., IT, US, UK, DE, ES, BR, IN)
  final String dialCode; // e.g. +39, +1, +44, +49, +34, +55, +91
  final String name;
  final String flagEmoji;
  final int activeSpamNumbersCount;

  CountryRegion({
    required this.code,
    required this.dialCode,
    required this.name,
    required this.flagEmoji,
    required this.activeSpamNumbersCount,
  });

  static List<CountryRegion> defaultSupportedRegions = [
    CountryRegion(code: 'IT', dialCode: '+39', name: 'Italia', flagEmoji: '🇮🇹', activeSpamNumbersCount: 48290),
    CountryRegion(code: 'US', dialCode: '+1', name: 'United States', flagEmoji: '🇺🇸', activeSpamNumbersCount: 194820),
    CountryRegion(code: 'UK', dialCode: '+44', name: 'United Kingdom', flagEmoji: '🇬🇧', activeSpamNumbersCount: 67310),
    CountryRegion(code: 'DE', dialCode: '+49', name: 'Deutschland', flagEmoji: '🇩🇪', activeSpamNumbersCount: 51200),
    CountryRegion(code: 'ES', dialCode: '+34', name: 'España', flagEmoji: '🇪🇸', activeSpamNumbersCount: 43100),
    CountryRegion(code: 'FR', dialCode: '+33', name: 'France', flagEmoji: '🇫🇷', activeSpamNumbersCount: 39500),
    CountryRegion(code: 'BR', dialCode: '+55', name: 'Brasil', flagEmoji: '🇧🇷', activeSpamNumbersCount: 112000),
    CountryRegion(code: 'IN', dialCode: '+91', name: 'India', flagEmoji: '🇮🇳', activeSpamNumbersCount: 235000),
  ];
}
