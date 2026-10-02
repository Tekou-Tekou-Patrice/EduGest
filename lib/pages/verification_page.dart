import 'package:edugest/components/app_colors.dart';
import 'package:edugest/components/my_button.dart';
import 'package:edugest/components/my_textfield.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

enum VerificationPurpose { registration, passwordReset }

class VerificationPage extends StatefulWidget {
  final VerificationPurpose purpose;
  final String contact;
  final String? userId;
  final String? initialCode;

  const VerificationPage({
    super.key,
    required this.purpose,
    required this.contact,
    this.userId,
    this.initialCode,
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _codeController.text = widget.initialCode!;
    }
  }

  Future<void> _submit() async {
    if (_codeController.text.trim().length != 6) {
      _show(context.tr('verificationCodeLength'));
      return;
    }
    if (widget.purpose == VerificationPurpose.passwordReset &&
        (_passwordController.text.length < 6 ||
            _passwordController.text != _confirmController.text)) {
      _show(context.tr('passwordValidation'));
      return;
    }
    setState(() => _loading = true);
    try {
      if (widget.purpose == VerificationPurpose.registration) {
        await ApiService.verifyRegistration(
          userId: widget.userId!,
          code: _codeController.text.trim(),
        );
      } else {
        await ApiService.resetPassword(
          contact: widget.contact,
          code: _codeController.text.trim(),
          newPassword: _passwordController.text,
        );
      }
      if (!mounted) return;
      _show(context.tr('verificationSuccess'));
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (error) {
      _show(ApiService.friendlyErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReset = widget.purpose == VerificationPurpose.passwordReset;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(context.tr('verification'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('verificationCodeTitle'),
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(context.tr('verificationCodeDescription')),
                const SizedBox(height: 24),
                MyTextfield(
                  controller: _codeController,
                  hintText: context.tr('sixCharacterCode'),
                  icon: Icons.verified_user,
                ),
                if (isReset) ...[
                  const SizedBox(height: 16),
                  MyTextfield(
                    controller: _passwordController,
                    hintText: context.tr('newPassword'),
                    icon: Icons.lock_reset,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  MyTextfield(
                    controller: _confirmController,
                    hintText: context.tr('confirmPassword'),
                    icon: Icons.lock_reset,
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
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : MyButton(
                          icon: Icons.check,
                          text: context.tr('validateCode'),
                          onTap: _submit,
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
