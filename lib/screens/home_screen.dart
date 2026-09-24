import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../providers/premium_provider.dart';
import '../core/services/ad_service.dart';
import 'tabs/shield_tab.dart';
import 'tabs/call_log_tab.dart';
import 'tabs/blacklist_tab.dart';
import 'tabs/radar_tab.dart';
import 'tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  final List<Widget> _tabs = const [
    ShieldTab(),
    CallLogTab(),
    BlacklistTab(),
    RadarTab(),
    SettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final premium = Provider.of<PremiumProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),

      // Sticky AdMob Banner in fondo allo schermo per utenti gratuiti
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!premium.isPremium && _isBannerLoaded && _bannerAd != null)
            Container(
              color: AppColors.surface,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),

          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.shield_outlined),
                activeIcon: const Icon(Icons.shield),
                label: loc.translate('tab_shield'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.phone),
                label: loc.translate('tab_call_log'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.block),
                label: loc.translate('tab_blacklist'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.radar),
                label: loc.translate('tab_radar'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings),
                label: loc.translate('tab_settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
