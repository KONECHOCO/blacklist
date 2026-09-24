import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/blacklist_provider.dart';

class BlacklistTab extends StatefulWidget {
  const BlacklistTab({super.key});

  @override
  State<BlacklistTab> createState() => _BlacklistTabState();
}

class _BlacklistTabState extends State<BlacklistTab> {
  final _patternController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BlacklistProvider>(context, listen: false).loadCustomRules();
    });
  }

  @override
  void dispose() {
    _patternController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showAddRuleDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: const Text('Aggiungi Regola Blocco'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _patternController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Numero o Prefisso (es. +39 02 9475*)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Descrizione (opzionale)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.spamRed),
              onPressed: () async {
                if (_patternController.text.isNotEmpty) {
                  await Provider.of<BlacklistProvider>(context, listen: false).addRule(
                    _patternController.text,
                    _descController.text,
                  );
                  _patternController.clear();
                  _descController.clear();
                  if (mounted) Navigator.of(ctx).pop();
                }
              },
              child: const Text('Salva Regola', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final blacklist = Provider.of<BlacklistProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blacklist Personale'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRuleDialog,
        backgroundColor: AppColors.spamRed,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Aggiungi Regola', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: blacklist.isLoading
          ? const Center(child: CircularProgressIndicator())
          : blacklist.customRules.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: blacklist.customRules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final rule = blacklist.customRules[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.spamRed.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.block, color: AppColors.spamRed),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rule['pattern'] as String,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if ((rule['description'] as String? ?? '').isNotEmpty)
                                  Text(
                                    rule['description'] as String,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
                            onPressed: () {
                              blacklist.deleteRule(rule['id'] as int);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Nessuna regola personalizzata',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Puoi bloccare singoli numeri o interi gruppi con il carattere jolly * (es. +39 02 94*)',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
