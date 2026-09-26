import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../services/app_state.dart';
import '../services/phone.dart';
import 'widgets.dart';

/// One-tap spam report: number, category chips, optional short description.
Future<void> showReportSheet(BuildContext context, {String? number, String category = 'telemarketing', String comment = ''}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ReportSheet(initial: number, category: category, comment: comment),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({this.initial, required this.category, required this.comment});
  final String? initial;
  final String category;
  final String comment;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  late final _number = TextEditingController(text: widget.initial ?? '');
  late final _comment = TextEditingController(text: widget.comment);
  late String _category = widget.category;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) _number.text = data!.text!.trim();
  }

  Future<void> _send() async {
    final t = L10n.of(context);
    final state = AppState.instance;
    final e164 = Phone.normalize(_number.text, state.country);
    if (e164 == null) {
      setState(() => _error = t.s('invalid_number'));
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final sent = await state.report(e164, _category, _comment.text.trim());
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    toast(context, t.s(sent ? 'report_sent' : 'report_offline'));
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.s('report_title'), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: _number,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              autofocus: widget.initial == null,
              decoration: InputDecoration(
                hintText: t.s('number_hint'),
                errorText: _error,
                prefixIcon: const Icon(Icons.phone_outlined),
                suffixIcon: IconButton(tooltip: t.s('paste'), icon: const Icon(Icons.content_paste), onPressed: _paste),
              ),
            ),
            const SizedBox(height: 18),
            Text(t.s('category_label'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in categories)
                  ChoiceChip(
                    label: Text(t.category(c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _comment,
              maxLength: 140,
              maxLines: 2,
              minLines: 1,
              decoration: InputDecoration(hintText: t.s('comment_hint')),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.block),
              label: Text(t.s('send_report')),
            ),
            const SizedBox(height: 10),
            Text(t.s('community_note'),
                textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
