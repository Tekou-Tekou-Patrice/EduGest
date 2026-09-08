import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/responsive_layout.dart';
import '../localization/app_localizations.dart';
import '../localization/locale_notifier.dart';
import '../models/app_user.dart';
import '../models/school_info.dart';
import '../service/api_service.dart';
import '../service/notification_service.dart';
import '../service/school_notifier.dart';

class Parametres extends StatefulWidget {
  final AppUser currentUser;
  const Parametres({super.key, required this.currentUser});

  @override
  State<Parametres> createState() => _ParametresState();
}

class _ParametresState extends State<Parametres> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  // Contrôleurs pour l'école
  final TextEditingController _schoolNameCtrl = TextEditingController();
  final TextEditingController _schoolCodeCtrl = TextEditingController();
  final TextEditingController _schoolYearCtrl = TextEditingController();
  final TextEditingController _schoolAddressCtrl = TextEditingController();
  final TextEditingController _schoolPhoneCtrl = TextEditingController();
  final TextEditingController _schoolEmailCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _archiveDate;

  bool _notificationsEnabled = true;
  String _languageCode = appLocale.value.languageCode;
  bool _isSaving = false;
  bool _isClosingYear = false;
  bool _isLoadingSchool = false;
  SchoolInfo? _currentSchool;
  Map<String, dynamic>? _paymentSettings;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
    _emailController = TextEditingController(text: widget.currentUser.email);

    if (widget.currentUser.displayRole == 'Fondateur' ||
        widget.currentUser.displayRole == 'Proviseur' ||
        widget.currentUser.displayRole == 'Secrétaire' ||
        widget.currentUser.displayRole == 'Comptable') {
      _fetchSchoolInfo();
    }
    if (widget.currentUser.displayRole == 'Fondateur' ||
        widget.currentUser.displayRole == 'Comptable') {
      _loadSubscriptionPaymentDetails();
    }
    _loadNotificationPreference();
  }

  Future<void> _loadSubscriptionPaymentDetails() async {
    try {
      final settings = await ApiService.getSaasSettings();
      if (mounted) setState(() => _paymentSettings = settings);
    } catch (error) {
      debugPrint('Erreur chargement moyens de paiement: $error');
    }
  }

  Future<void> _loadNotificationPreference() async {
    final enabled = NotificationService.instance.isEnabled;
    if (mounted) setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _fetchSchoolInfo() async {
    setState(() => _isLoadingSchool = true);
    try {
      final info = await ApiService.getSchoolInfo();
      if (info != null && mounted) {
        setState(() {
          _currentSchool = info;
          _schoolNameCtrl.text = info.name;
          _schoolCodeCtrl.text = info.code ?? '';
          _schoolYearCtrl.text = info.currentYearId;
          _schoolAddressCtrl.text = info.address;
          _schoolPhoneCtrl.text = info.phone;
          _schoolEmailCtrl.text = info.email ?? '';
          _startDate = info.startDate;
          _archiveDate = info.archiveDate;
          currentSchoolNotifier.setSchoolInfo(info);
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement infos école: $e");
    } finally {
      if (mounted) setState(() => _isLoadingSchool = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _schoolNameCtrl.dispose();
    _schoolCodeCtrl.dispose();
    _schoolYearCtrl.dispose();
    _schoolAddressCtrl.dispose();
    _schoolPhoneCtrl.dispose();
    _schoolEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isArchiveDate) async {
    final initialDate = isArchiveDate
        ? (_archiveDate ?? DateTime.now().add(const Duration(days: 300)))
        : (_startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isArchiveDate) {
          _archiveDate = picked;
        } else {
          _startDate = picked;
        }
      });
    }
  }

  Future<void> _saveAll() async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);

    try {
      if (widget.currentUser.displayRole == 'Fondateur' ||
          widget.currentUser.displayRole == 'Proviseur') {
        final updatedSchool = SchoolInfo(
          id: _currentSchool?.id ?? 'SCHOOL_1',
          name: _schoolNameCtrl.text.trim(),
          code: _schoolCodeCtrl.text.trim(),
          address: _schoolAddressCtrl.text.trim(),
          phone: _schoolPhoneCtrl.text.trim(),
          email: _schoolEmailCtrl.text.trim().isEmpty
              ? null
              : _schoolEmailCtrl.text.trim(),
          currentYearId: _schoolYearCtrl.text.trim(),
          startDate: _startDate,
          archiveDate: _archiveDate,
        );

        final saved = await ApiService.updateSchoolInfo(updatedSchool);
        if (mounted) {
          setState(() {
            _currentSchool = saved;
            currentSchoolNotifier.setSchoolInfo(saved);
          });
        }
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(loc.translate('preferencesSaved')),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text("Erreur lors de la sauvegarde: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleCloseYearNow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text("Clôturer & Sauvegarder l'année"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Voulez-vous sauvegarder et archiver immédiatement la session '${_schoolYearCtrl.text}' ?",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "• Un récapitulatif consolidé complet sera généré et enregistré dans la page de la fondatrice.\n"
              "• Le système sera mis en attente de la nouvelle année académique.",
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirmer la clôture"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isClosingYear = true);
    try {
      final recap = await ApiService.closeCurrentAcademicYear();
      await _fetchSchoolInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Année ${recap.label} sauvegardée et archivée avec succès !",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
      }
    } finally {
      if (mounted) setState(() => _isClosingYear = false);
    }
  }

  void _showStartNewYearDialog() {
    final labelCtrl = TextEditingController(text: "2025-2026");
    DateTime newStart = DateTime.now();
    DateTime newArchive = DateTime.now().add(const Duration(days: 300));

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.add_chart, color: AppColors.primary),
                SizedBox(width: 10),
                Text("Ouvrir une nouvelle année"),
              ],
            ),
            content: SizedBox(
              width: (MediaQuery.sizeOf(context).width - 80).clamp(
                280.0,
                450.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Saisissez les informations de la nouvelle session scolaire à démarrer :",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(
                        labelText: "Libellé de l'année (ex: 2025-2026)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      leading: const Icon(
                        Icons.date_range,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        "Date de début",
                        style: TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(newStart),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: newStart,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() => newStart = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      leading: const Icon(
                        Icons.archive_outlined,
                        color: Colors.orange,
                      ),
                      title: const Text(
                        "Date de sauvegarde & clôture prévue",
                        style: TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(newArchive),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: newArchive,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() => newArchive = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (labelCtrl.text.trim().isEmpty) return;
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(dialogCtx);
                  setState(() => _isSaving = true);
                  try {
                    await ApiService.startNewAcademicYear(
                      label: labelCtrl.text.trim(),
                      startDate: newStart,
                      archiveDate: newArchive,
                    );
                    await _fetchSchoolInfo();
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            "Nouvelle année académique ${labelCtrl.text.trim()} ouverte avec succès !",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Erreur: $e")),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  "Démarrer l'année",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bool canEditSchool = widget.currentUser.displayRole == 'Fondateur';
    final bool canViewSchool =
        canEditSchool ||
        widget.currentUser.displayRole == 'Proviseur' ||
        widget.currentUser.displayRole == 'Secrétaire';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('settingsTitle'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 20),
          _buildAccountCard(),
          const SizedBox(height: 25),

          if (canViewSchool) ...[
            _buildSchoolSection(),
            const SizedBox(height: 25),
          ],

          if (widget.currentUser.displayRole == 'Fondateur' ||
              widget.currentUser.displayRole == 'Comptable') ...[
            _buildSubscriptionPaymentSection(),
            const SizedBox(height: 25),
          ],

          _buildSectionTitle(loc.translate('preferences')),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildToggleOption(
                  icon: Icons.notifications,
                  label: loc.translate('notificationsActive'),
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    setState(() => _notificationsEnabled = value);
                    await NotificationService.instance.setEnabled(value);
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.desktop_windows,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Notifications Desktop / Bureau",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Alertes en temps réel sur Windows, macOS et Linux",
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPale,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final ok = await NotificationService.instance
                              .showTestNotification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? "Notification envoyée au bureau !"
                                      : "Erreur lors de l'envoi de la notification.",
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.send, size: 14),
                        label: const Text(
                          "Tester",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildDropdownOption(
                  icon: Icons.language,
                  label: loc.translate('applicationLanguage'),
                  value: _languageCode == 'en'
                      ? loc.translate('languageEnglish')
                      : loc.translate('languageFrench'),
                  items: [
                    loc.translate('languageFrench'),
                    loc.translate('languageEnglish'),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _languageCode = value == loc.translate('languageEnglish')
                          ? 'en'
                          : 'fr';
                      appLocale.setLocale(Locale(_languageCode));
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),
          Align(
            alignment: Alignment.centerLeft,
            child: MyButton(
              icon: _isSaving ? Icons.hourglass_top : Icons.save,
              text: _isSaving
                  ? "Sauvegarde en cours..."
                  : loc.translate('savePreferences'),
              onTap: _isSaving ? null : _saveAll,
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPaymentSection() {
    final settings = _paymentSettings;
    final expiresAt = _currentSchool?.subscriptionExpiresAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Paiement de votre abonnement EduGest'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: settings == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Effectuez le dépôt sur l’un des numéros ci-dessous, puis contactez l’administration pour la validation.',
                      style: TextStyle(color: AppColors.text),
                    ),
                    const SizedBox(height: 14),
                    _buildPaymentNumber(
                      icon: Icons.phone_android,
                      label: 'MTN Mobile Money',
                      number: settings['mtnNumber']?.toString() ?? '',
                      owner: settings['mtnName']?.toString() ?? '',
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentNumber(
                      icon: Icons.phone_android,
                      label: 'Orange Money',
                      number: settings['orangeNumber']?.toString() ?? '',
                      owner: settings['orangeName']?.toString() ?? '',
                      color: Colors.deepOrange,
                    ),
                    if ((settings['paymentInstructions']?.toString() ?? '')
                        .isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        settings['paymentInstructions'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (expiresAt != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Abonnement valide jusqu’au ${DateFormat('dd/MM/yyyy').format(expiresAt)}.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _currentSchool == null
                          ? null
                          : _showRenewSubscriptionDialog,
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Enregistrer un paiement'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _showRenewSubscriptionDialog() async {
    final schoolId = _currentSchool?.id.replaceFirst('SCHOOL_', '');
    if (schoolId == null || int.tryParse(schoolId) == null) return;
    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    final notesController = TextEditingController();
    int months = 1;
    String method = 'MTN Mobile Money';
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Paiement de l’abonnement'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: months,
                    decoration: const InputDecoration(labelText: 'Durée'),
                    items: const [1, 3, 12]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value mois'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => months = value ?? 1),
                  ),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Montant'),
                    validator: (value) => double.tryParse(value ?? '') == null
                        ? 'Montant invalide'
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    decoration: const InputDecoration(
                      labelText: 'Moyen de paiement',
                    ),
                    items:
                        const [
                              'MTN Mobile Money',
                              'Orange Money',
                              'Espèces',
                              'Virement',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setDialogState(() => method = value ?? method),
                  ),
                  TextField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Référence (facultatif)',
                    ),
                  ),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Note (facultatif)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.trim());
                  if (amount == null || amount <= 0) return;
                  try {
                    await ApiService.renewSubscription(
                      schoolId: schoolId,
                      actorId: widget.currentUser.id,
                      months: months,
                      amount: amount,
                      paymentMethod: method,
                      transactionRef: referenceController.text,
                      notes: notesController.text,
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    await _fetchSchoolInfo();
                  } catch (error) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Paiement impossible : $error')),
                      );
                    }
                  }
                },
                child: const Text('Valider'),
              ),
            ],
          ),
        ),
      );
    } finally {
      amountController.dispose();
      referenceController.dispose();
      notesController.dispose();
    }
  }

  Widget _buildPaymentNumber({
    required IconData icon,
    required String label,
    required String number,
    required String owner,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(number.isEmpty ? 'Non renseigné' : number),
                if (owner.isNotEmpty)
                  Text(
                    owner,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolSection() {
    final isWaiting = _currentSchool?.waitingForNewYear == true;
    final canEditSchool = widget.currentUser.role == UserRole.fondateur;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildSectionTitle(
              "Paramètres de l'Établissement & Année Académique",
            ),
            if (isWaiting)
              ElevatedButton.icon(
                onPressed: _showStartNewYearDialog,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  "Ouvrir Nouvelle Année",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (isWaiting)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.pause_circle_outline,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Année Scolaire Précédente Sauvegardée & Clôturée",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Toutes les opérations passées sont archivées dans la page Récapitulatif. Saisissez et démarrez la nouvelle année scolaire pour reprendre les saisies.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _showStartNewYearDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                  child: const Text(
                    "Démarrer",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

        if (_isLoadingSchool)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identité de l'établissement
                _buildInputField(
                  "Nom de l'école / Établissement",
                  _schoolNameCtrl,
                  "Requis",
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  "Code privé de l'école",
                  _schoolCodeCtrl,
                  "Requis",
                  readOnly: !canEditSchool,
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  "Année Scolaire / Session (ex: 2024-2025)",
                  _schoolYearCtrl,
                  "Requis",
                ),
                const SizedBox(height: 16),

                // Dates de gestion de l'année scolaire
                const Text(
                  "Gestion du cycle et de la sauvegarde automatique :",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final isMobile = ResponsiveLayout.isMobile(context);
                    final startWidget = InkWell(
                      onTap: () => _selectDate(context, false),
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.date_range,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Date début de l'année",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  Text(
                                    _startDate != null
                                        ? DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_startDate!)
                                        : "Non définie",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    final endWidget = InkWell(
                      onTap: () => _selectDate(context, true),
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.archive_outlined,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Date de sauvegarde & clôture",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    _archiveDate != null
                                        ? DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_archiveDate!)
                                        : "Non définie",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (isMobile) {
                      return Column(
                        children: [
                          startWidget,
                          const SizedBox(height: 10),
                          endWidget,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: startWidget),
                        const SizedBox(width: 12),
                        Expanded(child: endWidget),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  "ℹ️ À la date de sauvegarde, toutes les données de l'année seront enregistrées dans le récapitulatif de la fondatrice et l'application attendra l'ouverture de la nouvelle année.",
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  "Adresse / Localisation",
                  _schoolAddressCtrl,
                  "Requis",
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  "Téléphone de contact",
                  _schoolPhoneCtrl,
                  "Requis",
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  "Email officiel",
                  _schoolEmailCtrl,
                  "Optionnel",
                ),
                const SizedBox(height: 20),

                // Boutons d'actions spécifiques à l'année
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isClosingYear ? null : _handleCloseYearNow,
                      icon: const Icon(
                        Icons.archive,
                        size: 16,
                        color: Colors.deepOrange,
                      ),
                      label: Text(
                        _isClosingYear
                            ? "Clôture en cours..."
                            : "Sauvegarder & Clôturer l'année maintenant",
                        style: const TextStyle(color: Colors.deepOrange),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepOrange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showStartNewYearDialog,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        "Nouvelle Année Scolaire",
                        style: TextStyle(color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAccountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryPale,
            child: Text(
              widget.currentUser.initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentUser.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.currentUser.email,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.currentUser.displayRole,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String validationMessage, {
    bool readOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          border: InputBorder.none,
        ),
        validator: (value) =>
            value == null || value.isEmpty ? validationMessage : null,
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDropdownOption({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: value,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(color: AppColors.text),
              dropdownColor: AppColors.card,
              items: items
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(
                        option,
                        style: const TextStyle(color: AppColors.text),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
