import 'package:edugest/components/app_colors.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/pages/home_router.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/service/school_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../localization/app_localizations.dart';

class SchoolAccessPage extends StatefulWidget {
  final AppUser user;

  const SchoolAccessPage({super.key, required this.user});

  @override
  State<SchoolAccessPage> createState() => _SchoolAccessPageState();
}

class _SchoolAccessPageState extends State<SchoolAccessPage> {
  final _codeController = TextEditingController();
  final _schoolNameController = TextEditingController();
  String _schoolLevel = 'COLLEGE';
  bool _isSubmitting = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _schoolNameController.dispose();
    super.dispose();
  }

  Future<void> _joinSchool() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showMessage(context.tr('schoolCodeRequired'));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiService.joinSchoolByCode(userId: widget.user.id, code: code);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('schoolJoined'))));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _showMessage(ApiService.friendlyErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _createSchool() async {
    final name = _schoolNameController.text.trim();
    if (name.isEmpty) {
      _showMessage(context.tr('schoolNameCodeRequired'));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final school = await ApiService.createSchool(
        userId: widget.user.id,
        name: name,
        schoolLevel: _schoolLevel,
      );
      if (!mounted) return;
      ApiService.setActiveSchool(school.id);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.verified_outlined, color: AppColors.primary),
          title: Text(context.tr('generatedSchoolCodeTitle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('generatedSchoolCodeInstructions')),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SelectableText(
                  school.code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('generatedSchoolCodeSecurityNote'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: school.code));
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(context.tr('schoolCodeCopied'))),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: Text(context.tr('copySchoolCode')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('continueToSchool')),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeRouter(
            userRole: UserRole.fondateur.name,
            user: widget.user.copyWith(role: UserRole.fondateur),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showMessage(ApiService.friendlyErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(context.tr('joinOrCreateSchool'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('accessSchool'),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('accessSchoolDescription'),
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                Text(
                  '${context.tr('assignedRole')} : ${context.trRole(widget.user.role.name, schoolLevel: currentSchoolNotifier.value?.schoolLevel ?? _schoolLevel)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: context.tr('schoolCode'),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _joinSchool,
                  icon: const Icon(Icons.login),
                  label: Text(context.tr('joinByCode')),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),
                Text(
                  context.tr('createSchool'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _schoolNameController,
                  decoration: InputDecoration(
                    labelText: context.tr('newSchoolName'),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('generatedSchoolCodeInstructions'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _schoolLevel,
                  decoration: InputDecoration(
                    labelText: context.tr('schoolType'),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'PRIMARY',
                      child: Text(context.tr('schoolLevelPrimary')),
                    ),
                    DropdownMenuItem(
                      value: 'COLLEGE',
                      child: Text(context.tr('schoolLevelCollege')),
                    ),
                    DropdownMenuItem(
                      value: 'LYCEE',
                      child: Text(context.tr('schoolLevelLycee')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _schoolLevel = value);
                  },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _createSchool,
                  icon: const Icon(Icons.add_business),
                  label: Text(context.tr('createSchool')),
                ),
                if (_isSubmitting) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
