import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/responsive_layout.dart';
import '../localization/app_localizations.dart';
import '../models/app_user.dart';
import '../models/school_info.dart';
import '../service/api_service.dart';
import '../service/notification_service.dart';
import '../service/school_notifier.dart';

class Parametres extends StatefulWidget {
  final AppUser currentUser;
  final VoidCallback? onBack;

  const Parametres({super.key, required this.currentUser, this.onBack});

  @override
  State<Parametres> createState() => _ParametresState();
}

class _ParametresState extends State<Parametres> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  // ContrÃ´leurs pour l'Ã©cole
  final TextEditingController _schoolNameCtrl = TextEditingController();
  final TextEditingController _schoolCodeCtrl = TextEditingController();
  final TextEditingController _schoolYearCtrl = TextEditingController();
  final TextEditingController _schoolAddressCtrl = TextEditingController();
  final TextEditingController _schoolPhoneCtrl = TextEditingController();
  final TextEditingController _schoolEmailCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _archiveDate;

  bool _notificationsEnabled = true;
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
        widget.currentUser.displayRole == 'SecrÃ©taire' ||
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
      debugPrint("Erreur chargement infos Ã©cole: $e");
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
        ? (_archiveDate ?? DateTime.now().add(Duration(days: 300)))
        : (_startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
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
          schoolLevel: _currentSchool?.schoolLevel ?? 'COLLEGE',
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
          SnackBar(content: Text('${context.tr('saveErrorPrefix')} $e')),
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
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text(context.tr('closeAndSaveYear')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${context.tr('confirmCloseYear')} ${_schoolYearCtrl.text} ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              context.tr('closeYearDescription'),
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
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('confirmClosure')),
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
              '${context.tr('yearArchivedSuccess')} ${recap.label} !',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('errorPrefix')} $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isClosingYear = false);
    }
  }

  void _showStartNewYearDialog() {
    final labelCtrl = TextEditingController(text: "2025-2026");
    DateTime newStart = DateTime.now();
    DateTime newArchive = DateTime.now().add(Duration(days: 300));

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.add_chart, color: AppColors.primary),
                SizedBox(width: 10),
                Text(context.tr('openNewYear')),
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
                    Text(
                      context.tr('newYearDescription'),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: labelCtrl,
                      decoration: InputDecoration(
                        labelText: context.tr('academicYearLabel'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppColors.border),
                      ),
                      leading: Icon(Icons.date_range, color: AppColors.primary),
                      title: Text(
                        context.tr('startDate'),
                        style: TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(newStart),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Icon(Icons.edit_calendar),
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
                    SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppColors.border),
                      ),
                      leading: Icon(
                        Icons.archive_outlined,
                        color: Colors.orange,
                      ),
                      title: Text(
                        context.tr('scheduledSaveCloseDate'),
                        style: TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(newArchive),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      trailing: Icon(Icons.edit_calendar),
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
                child: Text(context.tr('cancel')),
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
                            '${context.tr('newAcademicYearStarted')} ${labelCtrl.text.trim()} !',
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
                child: Text(
                  context.tr('startYear'),
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
        widget.currentUser.displayRole == 'SecrÃ©taire';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: context.tr('back'),
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        title: Text(loc.translate('settingsTitle')),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('settingsTitle'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 20),
            _buildAccountCard(),
            SizedBox(height: 25),

            if (canViewSchool) ...[_buildSchoolSection(), SizedBox(height: 25)],

            if (widget.currentUser.displayRole == 'Fondateur' ||
                widget.currentUser.displayRole == 'Comptable') ...[
              _buildSubscriptionPaymentSection(),
              SizedBox(height: 25),
            ],

            _buildSectionTitle(loc.translate('preferences')),
            SizedBox(height: 16),
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
                ],
              ),
            ),
            SizedBox(height: 35),
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
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionPaymentSection() {
    final settings = _paymentSettings;
    final expiresAt = _currentSchool?.subscriptionExpiresAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context.tr('subscriptionPayment')),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: settings == null
              ? Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('subscriptionPaymentDescription'),
                      style: TextStyle(color: AppColors.text),
                    ),
                    SizedBox(height: 14),
                    _buildPaymentNumber(
                      icon: Icons.phone_android,
                      label: 'MTN Mobile Money',
                      number: settings['mtnNumber']?.toString() ?? '',
                      owner: settings['mtnName']?.toString() ?? '',
                      color: Colors.amber.shade800,
                    ),
                    SizedBox(height: 10),
                    _buildPaymentNumber(
                      icon: Icons.phone_android,
                      label: 'Orange Money',
                      number: settings['orangeNumber']?.toString() ?? '',
                      owner: settings['orangeName']?.toString() ?? '',
                      color: Colors.deepOrange,
                    ),
                    if ((settings['paymentInstructions']?.toString() ?? '')
                        .isNotEmpty) ...[
                      SizedBox(height: 12),
                      Text(
                        settings['paymentInstructions'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (expiresAt != null) ...[
                      SizedBox(height: 12),
                      Text(
                        '${context.tr('subscriptionValidUntil')} ${DateFormat('dd/MM/yyyy').format(expiresAt)}.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentNumber({
    required IconData icon,
    required String label,
    required String number,
    required String owner,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(number.isEmpty ? context.tr('notProvided') : number),
                if (owner.isNotEmpty)
                  Text(
                    owner,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
            _buildSectionTitle(context.tr('schoolSettings')),
            if (isWaiting)
              ElevatedButton.icon(
                onPressed: _showStartNewYearDialog,
                icon: Icon(Icons.add, size: 16, color: Colors.white),
                label: Text(
                  context.tr('openNewYear'),
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
          ],
        ),
        SizedBox(height: 16),

        if (isWaiting)
          Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.pause_circle_outline,
                  color: Colors.orange,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('previousYearArchived'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        context.tr('previousYearArchivedDescription'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _showStartNewYearDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                  child: Text(
                    context.tr('start'),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

        if (_isLoadingSchool)
          Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IdentitÃ© de l'Ã©tablissement
                _buildInputField(
                  context.tr('schoolNameLabel'),
                  _schoolNameCtrl,
                  context.tr('required'),
                ),
                SizedBox(height: 16),
                _buildInputField(
                  context.tr('privateSchoolCode'),
                  _schoolCodeCtrl,
                  context.tr('required'),
                  readOnly: !canEditSchool,
                ),
                SizedBox(height: 12),
                _buildInputField(
                  context.tr('schoolYearLabel'),
                  _schoolYearCtrl,
                  context.tr('required'),
                ),
                SizedBox(height: 16),

                // Dates de gestion de l'annÃ©e scolaire
                Text(
                  context.tr('cycleManagement'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final isMobile = ResponsiveLayout.isMobile(context);
                    final startWidget = InkWell(
                      onTap: () => _selectDate(context, false),
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: EdgeInsets.symmetric(
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
                            Icon(
                              Icons.date_range,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('yearStartDate'),
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
                                        : context.tr('notDefined'),
                                    style: TextStyle(
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
                        padding: EdgeInsets.symmetric(
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
                            Icon(
                              Icons.archive_outlined,
                              color: Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('saveCloseDate'),
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
                                        : context.tr('notDefined'),
                                    style: TextStyle(
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
                          SizedBox(height: 10),
                          endWidget,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: startWidget),
                        SizedBox(width: 12),
                        Expanded(child: endWidget),
                      ],
                    );
                  },
                ),
                SizedBox(height: 6),
                Text(
                  context.tr('saveCloseInfo'),
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                SizedBox(height: 16),

                _buildInputField(
                  context.tr('addressLocation'),
                  _schoolAddressCtrl,
                  context.tr('required'),
                ),
                SizedBox(height: 12),
                _buildInputField(
                  context.tr('contactPhone'),
                  _schoolPhoneCtrl,
                  context.tr('required'),
                ),
                SizedBox(height: 12),
                _buildInputField(
                  context.tr('officialEmail'),
                  _schoolEmailCtrl,
                  context.tr('optional'),
                ),
                SizedBox(height: 20),

                // Boutons d'actions spÃ©cifiques Ã  l'annÃ©e
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isClosingYear ? null : _handleCloseYearNow,
                      icon: Icon(
                        Icons.archive,
                        size: 16,
                        color: Colors.deepOrange,
                      ),
                      label: Text(
                        _isClosingYear
                            ? context.tr('closingInProgress')
                            : context.tr('saveAndCloseNow'),
                        style: TextStyle(color: Colors.deepOrange),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.deepOrange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showStartNewYearDialog,
                      icon: Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        context.tr('newSchoolYear'),
                        style: TextStyle(color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
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
      padding: EdgeInsets.all(20),
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
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentUser.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.currentUser.email,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  widget.currentUser.displayRole,
                  style: TextStyle(
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
      style: TextStyle(
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
          labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: AppColors.text),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
