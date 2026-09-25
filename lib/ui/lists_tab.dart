import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../services/app_state.dart';
import '../services/phone.dart';
import 'widgets.dart';

/// The user's own rules: blocked numbers, blocked ranges, always-allowed numbers.
class ListsTab extends StatelessWidget {
  const ListsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.s('tab_lists')),
          bottom: TabBar(tabs: [
            Tab(text: t.s('lists_blocked')),
            Tab(text: t.s('lists_ranges')),
            Tab(text: t.s('lists_allowed')),
          ]),
        ),
        body: const TabBarView(children: [_List(kind: 'blocked'), _List(kind: 'ranges'), _List(kind: 'allowed')]),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final state = context.watch<AppState>();
    final items = switch (kind) {
      'blocked' => state.blocked.keys.toList(),
      'ranges' => state.ranges.toList(),
      _ => state.allowed.toList(),
    }
      ..sort();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: kind,
        tooltip: t.s('add'),
        onPressed: () => _add(context, state),
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(t.s('empty_$kind'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
              itemBuilder: (context, i) {
                final item = items[i];
                final note = kind == 'blocked' ? state.blocked[item] ?? '' : '';
                return Dismissible(
                  key: ValueKey('$kind$item'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (_) => _remove(state, item),
                  child: ListTile(
                    leading: Icon(kind == 'allowed' ? Icons.check_circle_outline : Icons.block),
                    title: Text(kind == 'ranges' ? item : prettyNumber(item, state.country)),
                    subtitle: note.isEmpty ? null : Text(categories.contains(note) ? t.category(note) : note),
                    trailing: IconButton(
                      tooltip: t.s('remove'),
                      icon: const Icon(Icons.close),
                      onPressed: () => _remove(state, item),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _remove(AppState state, String item) {
    switch (kind) {
      case 'blocked':
        state.unblock(item);
      case 'ranges':
        state.removeRange(item);
      default:
        state.disallow(item);
    }
  }

  Future<void> _add(BuildContext context, AppState state) async {
    final t = L10n.of(context);
    final controller = TextEditingController(text: kind == 'ranges' ? '+${Phone.dialCode(state.country)} ' : '');
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialog) {
          Future<void> save() async {
            if (kind == 'ranges') {
              if (!await state.addRange(controller.text)) {
                setDialog(() => error = t.s('range_invalid'));
                return;
              }
            } else {
              final e164 = Phone.normalize(controller.text, state.country);
              if (e164 == null) {
                setDialog(() => error = t.s('invalid_number'));
                return;
              }
              kind == 'blocked' ? await state.block(e164) : await state.allow(e164);
            }
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          }

          return AlertDialog(
            title: Text(t.s('add')),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: kind == 'ranges' ? TextInputType.text : TextInputType.phone,
              onSubmitted: (_) => save(),
              decoration: InputDecoration(
                hintText: kind == 'ranges' ? null : t.s('number_hint'),
                helperText: kind == 'ranges' ? t.s('range_hint') : null,
                helperMaxLines: 3,
                errorText: error,
                errorMaxLines: 3,
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
              FilledButton(onPressed: save, child: Text(t.s('add'))),
            ],
          );
        },
      ),
    );
    controller.dispose();
  }
}
