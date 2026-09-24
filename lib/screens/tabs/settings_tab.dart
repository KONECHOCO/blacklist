import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/premium_provider.dart';
import '../../providers/shield_provider.dart';
import '../premium_modal.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final premium = Provider.of<PremiumProvider>(context);
    final shield = Provider.of<ShieldProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('tab_settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner Status VIP / Upgrade
          if (!premium.isPremium)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withOpacity(0.3),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.workspace_premium, color: Colors.black, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Passa a Blacklist VIP',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Elimina le pubblicità e ricevi aggiornamenti del database in background.',
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const PremiumModal(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Scopri l\'Offerta (€1,99/mese)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.successGreen),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: AppColors.successGreen),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Stato Abbonamento: VIP Attivo (Senza Pubblicità)',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 28),

          // Sezione Lingua App
          _buildSectionHeader('Lingua & Paese'),
          const SizedBox(height: 12),

          // Selector Lingua
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.language, color: AppColors.primaryCyan),
                    SizedBox(width: 14),
                    Text('Lingua dell\'App', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                  ],
                ),
                DropdownButton<String>(
                  value: premium.localeCode,
                  dropdownColor: AppColors.surface,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'it', child: Text('🇮🇹 Italiano')),
                    DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
                    DropdownMenuItem(value: 'es', child: Text('🇪🇸 Español')),
                    DropdownMenuItem(value: 'de', child: Text('🇩🇪 Deutsch')),
                    DropdownMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
                  ],
                  onChanged: (code) {
                    if (code != null) {
                      premium.setLocaleCode(code);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Selector Regione Database
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.location_on, color: AppColors.primaryCyan),
                    SizedBox(width: 14),
                    Text('Zona Database', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                  ],
                ),
                Text(
                  '${shield.selectedRegion.flagEmoji} ${shield.selectedRegion.name}',
                  style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          _buildSectionHeader('Info & Supporto'),
          const SizedBox(height: 12),

          _buildSettingsTile(
            icon: Icons.shield,
            title: 'Informativa sulla Privacy (GDPR)',
            subtitle: 'Nessuna rubrica caricata sui server',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(
            icon: Icons.star,
            title: 'Valuta l\'app su App Store / Play Store',
            subtitle: 'Aiutaci a combattere lo spam telefonico',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'Versione dell\'App',
            subtitle: 'Blacklist 1.0.0 (Global Release)',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryCyan),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
        onTap: onTap,
      ),
    );
  }
}
