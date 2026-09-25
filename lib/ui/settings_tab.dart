import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_config.dart';
import '../l10n.dart';
import '../monetization/premium.dart';
import '../services/app_state.dart';
import '../services/phone.dart';
import 'widgets.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final state = context.watch<AppState>();
    final premium = context.watch<Premium>();
    return Scaffold(
      appBar: AppBar(title: Text(t.s('tab_settings'))),
      body: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 32),
        children: [
          Section(children: [
            ListTile(
              leading: Text(flag(state.country), style: const TextStyle(fontSize: 24)),
              title: Text(t.s('country')),
              subtitle: Text('${state.country}  +${Phone.dialCode(state.country)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickCountry(context, state),
            ),
            const Divider(height: 1, indent: 16),
            ListTile(
              leading: const Icon(Icons.translate),
              title: Text(t.s('language')),
              subtitle: Text(state.language == null ? t.s('language_system') : L10n.languages[state.language]!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickLanguage(context, state),
            ),
          ]),
          if (premium.supported)
            Section(
              title: t.s('ads_title'),
              children: [
                if (premium.adFree)
                  ListTile(leading: const Icon(Icons.favorite, color: Colors.pink), title: Text(t.s('ad_free')))
                else
                  ListTile(
                    leading: const Icon(Icons.block_flipped),
                    title: Text(t.s('remove_ads')),
                    trailing: premium.busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(premium.price ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                    onTap: premium.busy ? null : () => _run(context, premium.buy),
                  ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: Text(t.s('restore')),
                  onTap: premium.busy ? null : () => _run(context, premium.restore),
                ),
              ],
            ),
          Section(
            title: t.s('how_title'),
            padding: const EdgeInsets.all(16),
            children: [Text(t.s('how_body'), style: const TextStyle(height: 1.4))],
          ),
          Section(children: [
            _link(Icons.privacy_tip_outlined, t.s('privacy'), privacyUrl),
            const Divider(height: 1, indent: 16),
            _link(Icons.help_outline, t.s('support'), supportUrl),
            const Divider(height: 1, indent: 16),
            _link(Icons.person_remove_outlined, t.s('removal_request'), removalUrl),
          ]),
          Center(
            child: Text('Blacklist Call Blocker · ${t.s('version')} 1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Widget _link(IconData icon, String label, String url) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      );

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    final t = L10n.of(context);
    await action();
    final outcome = Premium.instance.outcome;
    if (outcome != null && context.mounted) {
      toast(context, t.s({'failed': 'purchase_failed', 'notFound': 'nothing_to_restore', 'unavailable': 'purchase_unavailable'}[outcome]!));
    }
  }

  Future<void> _pickCountry(BuildContext context, AppState state) async {
    final list = {...countries, state.country}.toList();
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scroll) => ListView(
          controller: scroll,
          children: [
            for (final c in list)
              ListTile(
                leading: Text(flag(c), style: const TextStyle(fontSize: 24)),
                title: Text(c),
                subtitle: Text('+${Phone.dialCode(c)}'),
                trailing: c == state.country ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(c),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await state.setCountry(picked);
  }

  Future<void> _pickLanguage(BuildContext context, AppState state) async {
    final t = L10n.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scroll) => ListView(
          controller: scroll,
          children: [
            ListTile(
              title: Text(t.s('language_system')),
              trailing: state.language == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(''),
            ),
            for (final entry in L10n.languages.entries)
              ListTile(
                title: Text(entry.value),
                trailing: state.language == entry.key ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(entry.key),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await state.setLanguage(picked.isEmpty ? null : picked);
  }
}
