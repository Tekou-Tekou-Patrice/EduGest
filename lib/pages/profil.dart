import 'package:edugest/components/my_button.dart';
import 'package:edugest/components/my_textfield.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../localization/locale_notifier.dart';
import '../components/app_colors.dart';
import '../models/app_user.dart';
import '../service/school_notifier.dart';

class Profil extends StatefulWidget {
  final AppUser user;
  const Profil({super.key, required this.user});

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  String _languageCode = appLocale.value.languageCode;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    await appLocale.loadForUser(widget.user.id);
    if (mounted) {
      setState(() => _languageCode = appLocale.value.languageCode);
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    try {
      await ApiService.requestPasswordChangeCode(widget.user.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.friendlyErrorMessage(error))),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final codeController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('changePassword')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.tr('passwordCodeDescription')),
              SizedBox(height: 16),
              MyTextfield(
                controller: codeController,
                hintText: context.tr('sixCharacterCode'),
                icon: Icons.verified_user,
              ),
              SizedBox(height: 16),
              MyTextfield(
                controller: newPasswordController,
                hintText: context.tr('newPassword'),
                icon: Icons.lock_reset,
                obscureText: true,
              ),
              SizedBox(height: 16),
              MyTextfield(
                controller: confirmPasswordController,
                hintText: context.tr('confirmPassword'),
                icon: Icons.lock_reset,
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (codeController.text.trim().length != 6 ||
                  newPasswordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('enterCodeAndNewPassword')),
                  ),
                );
                return;
              }
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('passwordsDoNotMatch'))),
                );
                return;
              }

              try {
                await ApiService.confirmPasswordChange(
                  userId: widget.user.id,
                  code: codeController.text.trim(),
                  newPassword: newPasswordController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('passwordUpdated'))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ApiService.friendlyErrorMessage(e))),
                  );
                }
              }
            },
            child: Text(
              context.tr('validate'),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('myProfile'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        SizedBox(height: 24),

        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: AppColors.primaryPale,
                child: Text(
                  widget.user.initials,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
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
                      widget.user.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Text(
                      context.trRole(
                        widget.user.role.name,
                        schoolLevel: currentSchoolNotifier.value?.schoolLevel,
                      ),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 32),

        _buildSectionTitle(context.tr('personalInformation')),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                Icons.email_outlined,
                context.tr('auto_email'),
                widget.user.email,
              ),
              Divider(height: 24),
              _buildInfoRow(
                Icons.person_outline,
                context.tr('user'),
                widget.user.name,
              ),
              Divider(height: 24),
              _buildInfoRow(
                Icons.badge_outlined,
                context.tr('role'),
                context.trRole(
                  widget.user.role.name,
                  schoolLevel: currentSchoolNotifier.value?.schoolLevel,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 32),
        _buildSectionTitle(context.tr('applicationLanguage')),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _languageCode,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: 'fr',
                  child: Text(context.tr('languageFrench')),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(context.tr('languageEnglish')),
                ),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await appLocale.setLocaleForUser(widget.user.id, Locale(value));
                if (mounted) setState(() => _languageCode = value);
              },
            ),
          ),
        ),
        SizedBox(height: 32),
        _buildSectionTitle(context.tr('security')),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: MyButton(
            icon: Icons.lock_reset,
            text: context.tr('changePassword'),
            onTap: () => _showChangePasswordDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
