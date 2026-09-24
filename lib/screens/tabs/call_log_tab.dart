import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/call_log_item.dart';
import '../../providers/spam_database_provider.dart';
import '../report_spam_dialog.dart';

class CallLogTab extends StatelessWidget {
  const CallLogTab({super.key});

  @override
  Widget build(BuildContext context) {
    final spamProvider = Provider.of<SpamDatabaseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Chiamate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              spamProvider.loadInitialData();
            },
          ),
        ],
      ),
      body: spamProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : spamProvider.callLogs.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: spamProvider.callLogs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = spamProvider.callLogs[index];
                    return _buildCallLogTile(context, item);
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Nessuna chiamata recente',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Le chiamate in entrata ed i blocchi appariranno qui.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCallLogTile(BuildContext context, CallLogItem item) {
    final dateFormat = DateFormat('HH:mm - dd/MM');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isSpam ? AppColors.spamRed.withOpacity(0.08) : AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isSpam ? AppColors.spamRed.withOpacity(0.5) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          // Icona Tipo Chiamata
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.isSpam
                  ? AppColors.spamRed.withOpacity(0.2)
                  : AppColors.primaryCyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.isSpam
                  ? Icons.gpp_maybe
                  : (item.callType == CallType.missed
                      ? Icons.phone_missed
                      : Icons.phone_callback),
              color: item.isSpam ? AppColors.spamRed : AppColors.primaryCyan,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Dettagli Chiamata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.phoneNumber,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (item.callerName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.callerName!,
                    style: TextStyle(
                      color: item.isSpam ? AppColors.spamRed : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(item.timestamp),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),

          // Azione 1-Tap Flag as Spam
          if (item.isSpam)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.spamRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'BLOCCATO',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ReportSpamDialog(initialPhoneNumber: item.phoneNumber),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.spamRed,
                side: const BorderSide(color: AppColors.spamRed),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.flag, size: 14),
              label: const Text('Segnala', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
