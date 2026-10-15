import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_config.dart';
import '../demo.dart';
import '../l10n.dart';
import '../monetization/ads.dart';
import '../services/app_state.dart';
import '../services/native.dart';
import '../services/phone.dart';
import '../services/scam_rules.dart';
import 'report_sheet.dart';
import 'theme.dart';
import 'widgets.dart';

/// Scam messages: "Check a message" (offline analysis of a pasted SMS / chat
/// message), the iOS SMS filter and the user's own blocked words.
class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final _text = TextEditingController();
  final _keyword = TextEditingController();
  ScamCheck? _check;

  @override
  void initState() {
    super.initState();
    if (screenshotMode && Demo.tab == 2) {
      _text.text = Demo.scamMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) => _analyze());
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _keyword.dispose();
    super.dispose();
  }

  void _analyze() {
    final state = AppState.instance;
    FocusScope.of(context).unfocus();
    if (_text.text.trim().isEmpty) return;
    setState(() {
      _check = analyzeMessage(
        _text.text,
        keywords: state.smsKeywords,
        isReported: (raw) {
          final e164 = Phone.normalize(raw, state.country);
          return e164 != null && (state.blocked.containsKey(e164) || state.communityEntry(e164) != null);
        },
      );
    });
    Ads.instance.afterAction();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _text.text = data!.text!;
      _analyze();
    }
  }

  Future<void> _addKeyword(AppState state) async {
    await state.addSmsKeyword(_keyword.text);
    _keyword.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final state = context.watch<AppState>();
    final ios = Native.instance.isIOS;
    return Scaffold(
      appBar: AppBar(title: Text(t.s('tab_messages'))),
      body: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 32),
        children: [
          Section(
            title: t.s('check_title'),
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _text,
                minLines: 4,
                maxLines: 8,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(hintText: t.s('check_hint'), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(children: [
                OutlinedButton.icon(onPressed: _paste, icon: const Icon(Icons.content_paste), label: Text(t.s('paste'))),
                const Spacer(),
                FilledButton.icon(onPressed: _analyze, icon: const Icon(Icons.policy_outlined), label: Text(t.s('check_button'))),
              ]),
            ],
          ),
          if (_check != null) _Result(check: _check!, state: state),
          if (ios)
            Section(
              title: t.s('sms_filter_title'),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(t.s('sms_filter_body'), style: const TextStyle(height: 1.4)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(t.s('sms_steps'), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse('app-settings:')),
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(t.s('open_settings')),
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: state.smsStrict,
                  onChanged: state.setSmsStrict,
                  title: Text(t.s('sms_strict')),
                  subtitle: Text(t.s('sms_strict_desc')),
                ),
              ],
            ),
          Section(
            title: t.s('keywords_title'),
            padding: const EdgeInsets.all(16),
            children: [
              Text(t.s(ios ? 'keywords_desc_ios' : 'keywords_desc_android'), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              if (state.smsKeywords.isEmpty)
                Text(t.s('keywords_empty'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
              else
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final k in state.smsKeywords) InputChip(label: Text(k), onDeleted: () => state.removeSmsKeyword(k)),
                ]),
              const SizedBox(height: 12),
              TextField(
                controller: _keyword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addKeyword(state),
                decoration: InputDecoration(
                  hintText: t.s('keywords_hint'),
                  suffixIcon: IconButton(icon: const Icon(Icons.add), tooltip: t.s('add'), onPressed: () => _addKeyword(state)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Icon(Icons.lock_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text(t.s('msg_privacy'), style: Theme.of(context).textTheme.bodySmall)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.check, required this.state});
  final ScamCheck check;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final theme = Theme.of(context);
    final (color, icon) = switch (check.verdict) {
      'scam' => (brandRed, Icons.gpp_bad),
      'suspicious' => (warnAmber, Icons.warning_amber_rounded),
      _ => (safeGreen, Icons.verified_user_outlined),
    };
    return Section(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.s('verdict_msg_${check.verdict}'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
              Text(t.f('msg_score', {'n': check.score}), style: theme.textTheme.bodySmall),
            ]),
          ),
        ]),
        if (check.signals.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(t.s('signals_found'), style: theme.textTheme.titleSmall),
          for (final s in check.signals)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.error_outline, size: 18, color: color)),
                const SizedBox(width: 8),
                Expanded(child: Text(t.s('sig_$s'), style: const TextStyle(height: 1.35))),
              ]),
            ),
        ],
        if (check.links.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(t.s('links_found'), style: theme.textTheme.titleSmall),
          for (final l in check.links)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('\u2066$l\u2069', style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
            ),
        ],
        if (check.numbers.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final n in check.numbers)
              OutlinedButton.icon(
                onPressed: () => showReportSheet(context, number: n),
                icon: Icon(check.reportedNumbers.contains(n) ? Icons.report : Icons.flag_outlined,
                    color: check.reportedNumbers.contains(n) ? brandRed : null),
                label: Text('${t.s('report')} \u2066$n\u2069'),
              ),
          ]),
        ],
      ],
    );
  }
}
