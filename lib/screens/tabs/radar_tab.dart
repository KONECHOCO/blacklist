import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/spam_number.dart';
import '../../providers/spam_database_provider.dart';
import '../../providers/shield_provider.dart';
import '../../providers/premium_provider.dart';
import '../../core/services/ad_service.dart';

class RadarTab extends StatelessWidget {
  const RadarTab({super.key});

  @override
  Widget build(BuildContext context) {
    final spamProvider = Provider.of<SpamDatabaseProvider>(context);
    final shield = Provider.of<ShieldProvider>(context);
    final premium = Provider.of<PremiumProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Spam Radar ${shield.selectedRegion.flagEmoji} (${shield.selectedRegion.dialCode})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.primaryCyan),
            onPressed: () {
              // Rewarded Ad per gli utenti free per sbloccare l'aggiornamento istantaneo del DB
              AdService.instance.showRewardedAd(
                isPremium: premium.isPremium,
                onRewardEarned: (reward) {
                  spamProvider.syncRegionalDatabase(shield.selectedRegion.dialCode);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚡ Database Spam Regionale aggiornato all\'ultimo minuto!'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                },
                onDismissed: () {},
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Radar Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cardBg, AppColors.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.radar, color: AppColors.primaryCyan, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Radar Attivo in ${shield.selectedRegion.name}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Oltre ${shield.selectedRegion.activeSpamNumbersCount} numeri verificati nel database di zona.',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Titolo Sezione
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Numeri Spam del Giorno',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${spamProvider.spamNumbers.length} Segnalati',
                  style: const TextStyle(color: AppColors.primaryCyan, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lista Top Spam Numbers
            if (spamProvider.spamNumbers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('Nessun numero spam nella lista recente.'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: spamProvider.spamNumbers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final spam = spamProvider.spamNumbers[index];
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
                          child: const Icon(Icons.error_outline, color: AppColors.spamRed),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spam.phoneNumber,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${spam.category.displayName} • ${spam.reportsCount} Segnalazioni',
                                style: const TextStyle(color: AppColors.warningOrange, fontSize: 13),
                              ),
                              if (spam.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '"${spam.description}"',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.spamRed.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.spamRed),
                          ),
                          child: Text(
                            '${spam.trustScore} ★',
                            style: const TextStyle(color: AppColors.spamRed, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
