import 'package:edugest/components/app_colors.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/pages/home_router.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
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
  final _schoolCodeController = TextEditingController();
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
    _schoolCodeController.dispose();
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
    final code = _schoolCodeController.text.trim();
    if (name.isEmpty || code.isEmpty) {
      _showMessage(context.tr('schoolNameCodeRequired'));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final schoolId = await ApiService.createSchool(
        userId: widget.user.id,
        name: name,
        code: code,
        schoolLevel: _schoolLevel,
      );
      if (!mounted) return;
      ApiService.setActiveSchool(schoolId);
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
                  '${context.tr('assignedRole')} : ${widget.user.displayRole}',
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
                TextField(
                  controller: _schoolCodeController,
                  decoration: InputDecoration(
                    labelText: context.tr('privateSchoolCode'),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _schoolLevel,
                  decoration: const InputDecoration(
                    labelText: 'Type d’établissement',
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
