import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/premium_provider.dart';

class PremiumModal extends StatelessWidget {
  const PremiumModal({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = Provider.of<PremiumProvider>(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          
          // Badge VIP Icon
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium, color: Colors.black, size: 36),
          ),
          const SizedBox(height: 16),

          Text(
            'Blacklist VIP Protection',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Protezione completa senza limiti né pubblicità',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Features List
          _buildFeatureRow(Icons.visibility_off, 'Rimuovi tutte le pubblicità (No Banner/No Ads)'),
          const SizedBox(height: 12),
          _buildFeatureRow(Icons.sync, 'Aggiornamento Automatico DB Spam in Background'),
          const SizedBox(height: 12),
          _buildFeatureRow(Icons.filter_alt, 'Filtro SMS Phishing ed Anti-Truffa Avanzato'),
          const SizedBox(height: 12),
          _buildFeatureRow(Icons.bolt, 'Blocco Gruppi di Prefissi Illimitati'),

          const SizedBox(height: 28),

          // Abbonamento opzioni
          ElevatedButton(
            onPressed: () async {
              await premium.setPremium(true);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Congratulazioni! Ora sei un utente VIP Blacklist!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                alignment: Alignment.center,
                child: const Text(
                  'Attiva Prova Gratuita (3 Giorni Gratis) - Poi €1,99/mese',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Continua con la versione Gratuita (con Pubblicità)',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryCyan, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
