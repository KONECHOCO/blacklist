import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../services/app_state.dart';
import '../services/native.dart';
import 'report_sheet.dart';
import 'theme.dart';
import 'widgets.dart';

class ProtectionTab extends StatelessWidget {
  const ProtectionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final state = context.watch<AppState>();
    final android = Native.instance.isAndroid;
    return Scaffold(
      appBar: AppBar(title: const Text('Blacklist')),
      body: RefreshIndicator(
        onRefresh: () async {
          await state.refreshStatus();
          await state.sync(force: true);
        },
        child: ListView(
          padding: const EdgeInsets.only(top: 4, bottom: 96),
          children: [
            _StatusCard(state: state),
            _CommunityCard(state: state),
            Section(
              title: t.s('mode_title'),
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<Mode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: Mode.block, label: Text(t.s('mode_block')), icon: const Icon(Icons.block, size: 18)),
                    if (android)
                      ButtonSegment(value: Mode.silence, label: Text(t.s('mode_silence')), icon: const Icon(Icons.volume_off, size: 18)),
                    ButtonSegment(value: Mode.warn, label: Text(t.s('mode_warn')), icon: const Icon(Icons.warning_amber, size: 18)),
                  ],
                  selected: {!android && state.mode == Mode.silence ? Mode.block : state.mode},
                  onSelectionChanged: (s) => state.setMode(s.first),
                ),
                const SizedBox(height: 10),
                Text(t.s('mode_${state.mode.name}_desc'), style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            if (android)
              Section(children: [
                SwitchListTile(
                  title: Text(t.s('opt_hidden')),
                  subtitle: Text(t.s('opt_hidden_desc')),
                  value: state.blockHidden,
                  onChanged: (v) => state.setFlag('blockHidden', v),
                ),
                const Divider(height: 1, indent: 16),
                SwitchListTile(
                  title: Text(t.s('opt_foreign')),
                  subtitle: Text(t.s('opt_foreign_desc')),
                  value: state.blockForeign,
                  onChanged: (v) => state.setFlag('blockForeign', v),
                ),
                const Divider(height: 1, indent: 16),
                SwitchListTile(
                  title: Text(t.s('opt_unknown')),
                  subtitle: Text(t.s('opt_unknown_desc')),
                  value: state.askUnknown,
                  onChanged: (v) => state.setFlag('askUnknown', v),
                ),
              ])
            else
              Section(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(children: [
                    const Icon(Icons.phone_disabled_outlined),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t.s('ios_tip_title'), style: Theme.of(context).textTheme.titleMedium)),
                  ]),
                  const SizedBox(height: 8),
                  Text(t.s('ios_tip_body')),
                ],
              ),
            if (android) _RecentCalls(state: state),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final on = state.active;
    final color = on ? safeGreen : brandRed;
    final ios = Native.instance.isIOS;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, Colors.black, 0.25)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(on ? Icons.verified_user : Icons.gpp_maybe_outlined, color: Colors.white, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t.s(on ? 'status_on' : 'status_off'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 10),
              Text(t.s(on ? 'status_on_body' : (ios ? 'status_off_ios' : 'status_off_android')),
                  style: const TextStyle(fontSize: 15, height: 1.35, color: Colors.white)),
              if (!on && ios) ...[
                const SizedBox(height: 8),
                Text(t.s('ios_steps'), style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ],
              if (!on) ...[
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: color),
                  onPressed: () async {
                    await Native.instance.requestActivation();
                    await state.refreshStatus();
                    await state.apply();
                  },
                  child: Text(t.s(ios ? 'open_settings' : 'activate')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final theme = Theme.of(context);
    final updated = state.listUpdatedAt == 0
        ? t.s('db_never')
        : t.f('db_updated', {'time': relativeTime(context, DateTime.fromMillisecondsSinceEpoch(state.listUpdatedAt))});
    return Section(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(flag(state.country), style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.f('db_numbers', {'n': NumberFormat.decimalPattern(t.code).format(state.community.length)}), style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(state.syncError != null ? t.s('sync_error') : updated,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: state.syncError != null ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            state.syncing
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(tooltip: t.s('update_now'), icon: const Icon(Icons.refresh), onPressed: () => state.sync(force: true)),
          ],
        ),
      ],
    );
  }
}

class _RecentCalls extends StatelessWidget {
  const _RecentCalls({required this.state});
  final AppState state;

  static const _icons = {
    'block': (Icons.block, brandRed),
    'silence': (Icons.volume_off, warnAmber),
    'warn': (Icons.warning_amber, warnAmber),
    'allow': (Icons.check_circle_outline, safeGreen),
    'unknown': (Icons.help_outline, Colors.grey),
  };

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final calls = state.log.take(30).toList();
    return Section(
      title: t.s('recent_calls'),
      children: [
        if (calls.isEmpty)
          Padding(padding: const EdgeInsets.all(16), child: Text(t.s('no_calls')))
        else
          for (final call in calls)
            ListTile(
              leading: Icon(_icons[call.action]?.$1 ?? Icons.call, color: _icons[call.action]?.$2),
              title: Text(call.number.isEmpty ? t.s('hidden_number') : prettyNumber(call.number, state.country)),
              subtitle: Text([
                t.s('act_${call.action}'),
                if (call.category.isNotEmpty) t.category(call.category),
                relativeTime(context, call.at),
              ].join(' · ')),
              trailing: call.number.isEmpty || state.blocked.containsKey(call.number)
                  ? null
                  : IconButton(
                      tooltip: t.s('report'),
                      icon: const Icon(Icons.flag_outlined),
                      onPressed: () => showReportSheet(context, number: call.number),
                    ),
            ),
      ],
    );
  }
}
