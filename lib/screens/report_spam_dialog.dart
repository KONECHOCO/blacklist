import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/spam_number.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../providers/spam_database_provider.dart';
import '../providers/shield_provider.dart';
import '../providers/premium_provider.dart';
import '../core/services/ad_service.dart';

class ReportSpamDialog extends StatefulWidget {
  final String? initialPhoneNumber;

  const ReportSpamDialog({super.key, this.initialPhoneNumber});

  @override
  State<ReportSpamDialog> createState() => _ReportSpamDialogState();
}

class _ReportSpamDialogState extends State<ReportSpamDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  SpamCategory _selectedCategory = SpamCategory.telemarketing;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhoneNumber ?? '');
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final shield = Provider.of<ShieldProvider>(context, listen: false);
    final spamProvider = Provider.of<SpamDatabaseProvider>(context, listen: false);
    final premium = Provider.of<PremiumProvider>(context, listen: false);

    await spamProvider.reportSpamNumber(
      phoneNumber: _phoneController.text.trim(),
      countryCode: shield.selectedRegion.dialCode,
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_phoneController.text} inserito con successo nel database Spam!'),
          backgroundColor: AppColors.successGreen,
        ),
      );

      // Trigger Interstitial Ad per utenti free
      AdService.instance.showInterstitialAd(
        onComplete: () {},
        isPremium: premium.isPremium,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.spamRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.gpp_maybe, color: AppColors.spamRed),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.translate('report_spam_title'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  loc.translate('report_spam_desc'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                
                // Campo Numero di Telefono
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Numero di Telefono',
                    hintText: '+39 02...',
                    prefixIcon: const Icon(Icons.phone, color: AppColors.primaryCyan),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Inserisci un numero valido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Selettore Categoria Spam
                Text(
                  loc.translate('category_label'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<SpamCategory>(
                      value: _selectedCategory,
                      dropdownColor: AppColors.surface,
                      isExpanded: true,
                      items: SpamCategory.values.map((cat) {
                        return DropdownMenuItem<SpamCategory>(
                          value: cat,
                          child: Text(
                            cat.displayName,
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Descrizione Breve
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: loc.translate('description_label'),
                    hintText: loc.translate('description_hint'),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Pulsante Inserisci (1-Tap)
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.spamRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.person_remove),
                  label: Text(
                    loc.translate('submit_report'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
