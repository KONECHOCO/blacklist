import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/ad_service.dart';
import 'providers/shield_provider.dart';
import 'providers/spam_database_provider.dart';
import 'providers/blacklist_provider.dart';
import 'providers/premium_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inizializzazione SDK AdMob
  await AdService.instance.initialize();

  runApp(const BlacklistApp());
}

class BlacklistApp extends StatelessWidget {
  const BlacklistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ShieldProvider()),
        ChangeNotifierProvider(create: (_) => SpamDatabaseProvider()..loadInitialData()),
        ChangeNotifierProvider(create: (_) => BlacklistProvider()..loadCustomRules()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()..loadSettings()),
      ],
      child: Consumer<PremiumProvider>(
        builder: (context, premium, child) {
          return MaterialApp(
            title: 'Blacklist',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            locale: Locale(premium.localeCode),
            supportedLocales: const [
              Locale('it', ''),
              Locale('en', ''),
              Locale('es', ''),
              Locale('de', ''),
              Locale('fr', ''),
            ],
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
