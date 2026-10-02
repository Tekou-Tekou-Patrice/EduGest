import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../localization/locale_notifier.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../service/api_service.dart';
import '../service/school_notifier.dart';
import '../models/app_user.dart';

class InscriptionStaff extends StatefulWidget {
  final AppUser? currentUser;
  final VoidCallback? onSuccess;
  const InscriptionStaff({super.key, this.currentUser, this.onSuccess});

  @override
  State<InscriptionStaff> createState() => _InscriptionStaffState();
}

class _InscriptionStaffState extends State<InscriptionStaff> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedRole = 'ENSEIGNANT';
  bool _isLoading = false;

  String get _schoolLevel =>
      currentSchoolNotifier.value?.schoolLevel ?? 'COLLEGE';

  bool get _isPrimarySchool => _schoolLevel == 'PRIMARY';

  List<String> get _roles {
    switch (widget.currentUser?.role) {
      case UserRole.fondateur:
        return [
          'PROVISEUR',
          if (!_isPrimarySchool) 'CENSEUR',
          if (!_isPrimarySchool) 'SURVEILLANT_GENERAL',
          'SECRETAIRE',
          'COMPTABLE',
          'ENSEIGNANT',
        ];
      case UserRole.proviseur:
        return ['SECRETAIRE'];
      case UserRole.secretaire:
        return [
          if (!_isPrimarySchool) 'CENSEUR',
          if (!_isPrimarySchool) 'SURVEILLANT_GENERAL',
          'COMPTABLE',
          'ENSEIGNANT',
        ];
      default:
        return [];
    }
  }

  String _roleLabel(String role) {
    if (role == 'PROVISEUR' && _isPrimarySchool) {
      return context.tr('role_primaryDirector');
    }
    if (role == 'ENSEIGNANT' && _isPrimarySchool) {
      return context.tr('role_primaryTeacher');
    }
    final roleKey = switch (role) {
      'PROVISEUR' => 'role_proviseur',
      'CENSEUR' => 'role_censeur',
      'SURVEILLANT_GENERAL' => 'role_surveillantGeneral',
      'SECRETAIRE' => 'role_secretaire',
      'COMPTABLE' => 'role_comptable',
      'ENSEIGNANT' => 'role_enseignant',
      _ => null,
    };
    return roleKey == null ? role : context.tr(roleKey);
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('staffFieldsRequired'))),
      );
      return;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('passwordTooShort'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.registerStaff(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        registeredByUserId: widget.currentUser!.id,
        phone: _phoneController.text.trim(),
        language: appLocale.value.languageCode,
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${context.tr('staffAccountCreated')} ${_roleLabel(_selectedRole)} !",
              ),
            ),
          );
          _clearForm();
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? context.tr('saveError')),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.friendlyErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneController.clear();
    if (_roles.isNotEmpty) setState(() => _selectedRole = _roles.first);
  }

  @override
  Widget build(BuildContext context) {
    final roles = _roles;
    if (roles.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 42, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              context.tr('staffRecruitmentForbidden'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('staffRegistrationTitle'),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        SizedBox(height: 8),
        Text(
          context.tr('staffSignupDescription'),
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        SizedBox(height: 30),

        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyTextfield(
                controller: _nameController,
                hintText: context.tr('fullName'),
                icon: Icons.person_outline,
              ),
              SizedBox(height: 16),
              MyTextfield(
                controller: _phoneController,
                hintText: context.tr('phoneRequired'),
                icon: Icons.phone_android,
              ),
              SizedBox(height: 16),
              MyTextfield(
                controller: _emailController,
                hintText: context.tr('professionalEmail'),
                icon: Icons.email_outlined,
              ),
              SizedBox(height: 16),
              MyTextfield(
                controller: _passwordController,
                hintText: context.tr('temporaryPassword'),
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.tr('passwordCharacteristics'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.tr('assignedPosition'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: roles.contains(_selectedRole)
                    ? _selectedRole
                    : roles.first,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    Icons.admin_panel_settings,
                    color: AppColors.primary,
                  ),
                ),
                items: roles
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(_roleLabel(r)),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              SizedBox(height: 40),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: MyButton(
                        icon: Icons.person_add_alt_1,
                        text: context.tr('createStaffAccount'),
                        onTap: _handleRegister,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
