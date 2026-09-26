import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_config.dart';
import '../demo.dart';
import '../l10n.dart';
import '../monetization/ads.dart';
import '../services/api.dart';
import '../services/app_state.dart';
import '../services/phone.dart';
import 'report_sheet.dart';
import 'widgets.dart';

/// "Who called me?" — community verdict, categories and comments for a number.
class LookupTab extends StatefulWidget {
  const LookupTab({super.key});

  @override
  State<LookupTab> createState() => _LookupTabState();
}

class _LookupTabState extends State<LookupTab> {
  final _query = TextEditingController();
  NumberInfo? _info;
  String? _e164;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (screenshotMode && Demo.tab == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search(Phone.display(Demo.lookupNumber, Demo.country)));
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search([String? value]) async {
    final t = L10n.of(context);
    final state = AppState.instance;
    if (value != null) _query.text = value;
    FocusScope.of(context).unfocus();
    final e164 = Phone.normalize(_query.text, state.country);
    if (e164 == null) {
      setState(() => _error = t.s('invalid_number'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _e164 = e164;
    });
    NumberInfo? info;
    try {
      info = await Api.instance.lookup(e164, state.country);
    } catch (_) {}
    if (!mounted) return;
    if (info == null) {
      // Offline fallback: the downloaded country list.
      final row = state.communityEntry(e164);
      info = row == null
          ? null
          : NumberInfo({'number': e164, 'reports': 3, 'score': row[2], 'spam': true, 'category': row[1], 'categories': {row[1]: 1}});
    }
    setState(() {
      _loading = false;
      _info = info;
      if (info == null) _error = t.s('lookup_error');
    });
    Ads.instance.afterAction();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final state = context.watch<AppState>();
    final trending = (state.stats?['trending'] as List? ?? []).cast<Map>();
    return Scaffold(
      appBar: AppBar(title: Text(t.s('tab_lookup'))),
      body: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: TextField(
              controller: _query,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: t.s('lookup_hint'),
                errorText: _error,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loading
                    ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(icon: const Icon(Icons.arrow_forward), tooltip: t.s('search'), onPressed: _search),
              ),
            ),
          ),
          if (_info != null && _e164 != null) _Result(info: _info!, e164: _e164!, state: state),
          if (trending.isNotEmpty)
            Section(
              title: t.s('trending'),
              children: [
                for (final row in trending)
                  ListTile(
                    leading: ScoreBadge(score: (row['score'] as num).toInt(), size: 36),
                    title: Text(prettyNumber(row['number'] as String, state.country)),
                    subtitle: Text(t.f('reports_count', {'n': row['reports']})),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _search(row['number'] as String),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.info, required this.e164, required this.state});
  final NumberInfo info;
  final String e164;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final theme = Theme.of(context);
    final blocked = state.blocked.containsKey(e164);
    final allowed = state.allowed.contains(e164);
    final verdict = info.score >= 7 ? 'verdict_spam' : (info.reports > 0 ? 'verdict_suspicious' : 'verdict_clean');
    final cats = info.categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Section(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          ScoreBadge(score: info.reports == 0 ? 0 : info.score, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(prettyNumber(e164, state.country), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                [
                  t.s(verdict),
                  if (info.reports > 0) t.f('reports_count', {'n': info.reports}),
                  if (info.reports > 0) t.f('score', {'n': info.score}),
                ].join(' · '),
                style: TextStyle(color: scoreColor(info.reports == 0 ? 0 : info.score), fontWeight: FontWeight.w600),
              ),
              if (blocked || allowed)
                Text(t.s(blocked ? 'blocked_by_you' : 'allowed_by_you'), style: theme.textTheme.bodySmall),
            ]),
          ),
        ]),
        if (cats.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final c in cats) Chip(label: Text('${t.category(c.key)} · ${c.value}'), visualDensity: VisualDensity.compact),
          ]),
        ],
        if (info.comments.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(t.s('comments'), style: theme.textTheme.titleSmall),
          for (final c in info.comments)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.format_quote, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text('${c['text']}')),
              ]),
            ),
        ],
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (!blocked)
            FilledButton.icon(
              onPressed: () => showReportSheet(context, number: e164),
              icon: const Icon(Icons.flag_outlined),
              label: Text(t.s('report')),
            ),
          OutlinedButton.icon(
            onPressed: () => blocked ? state.unblock(e164) : state.block(e164),
            icon: Icon(blocked ? Icons.lock_open : Icons.block),
            label: Text(t.s(blocked ? 'unblock' : 'block')),
          ),
          if (!allowed)
            TextButton.icon(onPressed: () => state.allow(e164), icon: const Icon(Icons.check), label: Text(t.s('allow'))),
        ]),
      ],
    );
  }
}
