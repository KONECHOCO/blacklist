import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n.dart';
import 'monetization/ads.dart';
import 'monetization/premium.dart';
import 'services/app_state.dart';
import 'ui/home.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.init();
  await Premium.instance.init();
  await Ads.instance.init();
  runApp(const BlacklistApp());
}

class BlacklistApp extends StatelessWidget {
  const BlacklistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppState.instance),
        ChangeNotifierProvider.value(value: Premium.instance),
      ],
      child: Selector<AppState, String?>(
        selector: (_, s) => s.language,
        builder: (context, language, _) => MaterialApp(
          title: 'Blacklist',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          locale: language == null ? null : Locale(language),
          supportedLocales: L10n.languages.keys.map(Locale.new),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          localeResolutionCallback: (device, supported) {
            final code = device?.languageCode;
            return supported.firstWhere((l) => l.languageCode == code, orElse: () => const Locale('en'));
          },
          home: const HomeShell(),
        ),
      ),
    );
  }
}
