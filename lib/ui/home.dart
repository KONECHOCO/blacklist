import 'dart:async';

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../demo.dart';
import '../l10n.dart';
import '../monetization/ads.dart';
import '../services/app_state.dart';
import '../services/native.dart';
import '../services/phone.dart';
import 'lists_tab.dart';
import 'lookup_tab.dart';
import 'protection_tab.dart';
import 'report_sheet.dart';
import 'settings_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = screenshotMode ? Demo.tab : 0;
  StreamSubscription<String>? _reports;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reports = Native.instance.reportRequests.listen(_openReport);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (screenshotMode) {
      if (Demo.reportSheet) {
        showReportSheet(context, number: Phone.display(Demo.lookupNumber, Demo.country), category: 'telemarketing', comment: Demo.reportComment);
      }
      return;
    }
    final state = AppState.instance;
    await state.refreshStatus();
    await state.apply();
    if (state.needsSync) unawaited(state.sync());
    final launchNumber = await Native.instance.takeLaunchNumber();
    if (launchNumber != null && launchNumber.isNotEmpty) {
      _openReport(launchNumber);
    } else {
      await Ads.instance.showLaunch();
    }
  }

  void _openReport(String number) {
    if (!mounted) return;
    setState(() => _tab = 0);
    showReportSheet(context, number: number);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle != AppLifecycleState.resumed) return;
    final state = AppState.instance;
    state.refreshStatus();
    if (state.needsSync) state.sync();
    Native.instance.takeLaunchNumber().then((n) {
      if (n != null && n.isNotEmpty) _openReport(n);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reports?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    const pages = [ProtectionTab(), LookupTab(), ListsTab(), SettingsTab()];
    return Scaffold(
      // Phone-width column on iPad and tablets.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: IndexedStack(index: _tab, children: pages),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SafeArea(top: false, bottom: false, child: Center(child: BannerSlot())),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.shield_outlined), selectedIcon: const Icon(Icons.shield), label: t.s('tab_protection')),
              NavigationDestination(icon: const Icon(Icons.search), label: t.s('tab_lookup')),
              NavigationDestination(icon: const Icon(Icons.block_outlined), selectedIcon: const Icon(Icons.block), label: t.s('tab_lists')),
              NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: t.s('tab_settings')),
            ],
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => showReportSheet(context),
              icon: const Icon(Icons.flag_outlined),
              label: Text(t.s('report_number')),
            )
          : null,
    );
  }
}
