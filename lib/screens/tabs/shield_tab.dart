import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/country_region.dart';
import '../../core/models/spam_number.dart';
import '../../providers/shield_provider.dart';
import '../../providers/spam_database_provider.dart';
import '../report_spam_dialog.dart';

class ShieldTab extends StatefulWidget {
  const ShieldTab({super.key});

  @override
  State<ShieldTab> createState() => _ShieldTabState();
}

class _ShieldTabState extends State<ShieldTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final shield = Provider.of<ShieldProvider>(context);
    final spamProvider = Provider.of<SpamDatabaseProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header con Selettore Paese / Zona Geografica
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('app_title'),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 28,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Text(
                    'Filtro Antispam Globale',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              
              // Selettore Paese (Database per Zona)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CountryRegion>(
                    value: shield.selectedRegion,
                    dropdownColor: AppColors.surface,
                    items: CountryRegion.defaultSupportedRegions.map((region) {
                      return DropdownMenuItem<CountryRegion>(
                        value: region,
                        child: Row(
                          children: [
                            Text(region.flagEmoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              region.dialCode,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (region) {
                      if (region != null) {
                        shield.setSelectedRegion(region);
                        spamProvider.syncRegionalDatabase(region.dialCode);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Protection Shield Card
          GestureDetector(
            onTap: () => shield.toggleProtection(),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: shield.isProtectionActive
                    ? AppColors.cardGradient
                    : LinearGradient(
                        colors: [AppColors.surface, AppColors.cardBg],
                      ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: shield.isProtectionActive
                      ? AppColors.primaryCyan.withOpacity(0.5)
                      : AppColors.cardBorder,
                  width: 1.5,
                ),
                boxShadow: shield.isProtectionActive
                    ? [
                        BoxShadow(
                          color: AppColors.primaryCyan.withOpacity(0.15),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  // Animated Shield Button
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: shield.isProtectionActive
                          ? AppColors.primaryGradient
                          : const LinearGradient(
                              colors: [Color(0xFF334155), Color(0xFF1E293B)],
                            ),
                      boxShadow: shield.isProtectionActive
                          ? [
                              BoxShadow(
                                color: AppColors.primaryCyan.withOpacity(0.4),
                                blurRadius: 20,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      shield.isProtectionActive ? Icons.verified_user : Icons.shield_outlined,
                      size: 52,
                      color: shield.isProtectionActive ? Colors.black : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    shield.isProtectionActive
                        ? loc.translate('shield_active')
                        : loc.translate('shield_inactive'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: shield.isProtectionActive ? AppColors.primaryCyan : AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shield.isProtectionActive
                        ? loc.translate('shield_desc_active')
                        : loc.translate('shield_desc_inactive'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Statistiche Voci & DB
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.phone_disabled,
                  iconColor: AppColors.spamRed,
                  value: '${shield.blockedCallsCount}',
                  label: loc.translate('blocked_calls_count'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.storage,
                  iconColor: AppColors.primaryCyan,
                  value: '${shield.selectedRegion.activeSpamNumbersCount}',
                  label: loc.translate('active_spam_db'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Ricerca Rapida Numero nel DB
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: loc.translate('quick_search_hint'),
                hintStyle: const TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
                icon: const Icon(Icons.search, color: AppColors.primaryCyan),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          spamProvider.clearSearch();
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                spamProvider.searchNumber(val);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Risultato Ricerca
          if (spamProvider.isSearching)
            const Center(child: CircularProgressIndicator())
          else if (spamProvider.searchResult != null)
            _buildSearchResultCard(context, spamProvider.searchResult!)
          else if (_searchController.text.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.successGreen),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Nessuna segnalazione di spam trovata per questo numero.'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.spamRed),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => ReportSpamDialog(initialPhoneNumber: _searchController.text),
                        );
                      },
                      child: const Text('Segnala', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Pulsante Rapido Segnala Spam 1-Tap
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ReportSpamDialog(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.spamRed.withOpacity(0.2),
              foregroundColor: AppColors.spamRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.spamRed),
              ),
            ),
            icon: const Icon(Icons.person_add),
            label: const Text(
              'Aggiungi Numero Spam con 1-Tap',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(BuildContext context, SpamNumber spam) {
    return Card(
      color: AppColors.spamRed.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.spamRed, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.spamRed, size: 24),
                const SizedBox(width: 10),
                Text(
                  spam.phoneNumber,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.spamRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Spam Score: ${spam.trustScore}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Categoria: ${spam.category.displayName}',
              style: const TextStyle(color: AppColors.warningOrange, fontWeight: FontWeight.bold),
            ),
            if (spam.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Note: "${spam.description}"',
                style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Segnalato ${spam.reportsCount} volte dalla community.',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
