import 'package:edugest/components/app_colors.dart';
import 'package:edugest/components/my_button.dart';
import 'package:edugest/components/my_sidebar.dart';
import 'package:edugest/components/my_textfield.dart';
import 'package:edugest/components/responsive_layout.dart';
import 'package:edugest/localization/app_localizations.dart';
import 'package:edugest/localization/locale_notifier.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/pages/school_selection_page.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/service/auth_session_service.dart';
import 'package:edugest/pages/verification_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLogin = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  List<SidebarSection> get _sidebarSections => [
    SidebarSection(
      title: 'EduGest Info',
      items: [
        SidebarItem(icon: Icons.check, label: context.tr('gradeManagement')),
        SidebarItem(icon: Icons.check, label: context.tr('paymentManagement')),
        SidebarItem(icon: Icons.check, label: context.tr('studentManagement')),
        SidebarItem(icon: Icons.check, label: context.tr('courseManagement')),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: isMobile
          ? Drawer(child: MySidebar(sections: _sidebarSections))
          : null,
      appBar: isMobile
          ? AppBar(
              backgroundColor: AppColors.sidebarBg,
              title: Text(
                _isLogin
                    ? loc.translate('loginTitle')
                    : loc.translate('createAccount'),
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              iconTheme: IconThemeData(color: Colors.white),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) MySidebar(sections: _sidebarSections),
          Expanded(child: _buildAuthForm(isMobile)),
        ],
      ),
    );
  }

  Widget _buildAuthForm(bool isMobile) {
    final loc = AppLocalizations.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 25 : 80),
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isLogin
                    ? loc.translate('loginTitle')
                    : loc.translate('createAccount'),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 10),
              Text(
                _isLogin
                    ? loc.translate('loginSubtitle')
                    : loc.translate('signupDescription'),
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
              SizedBox(height: 40),

              if (!_isLogin) ...[
                MyTextfield(
                  controller: _nameController,
                  icon: Icons.person,
                  hintText: loc.translate('fullNameHint'),
                ),
                SizedBox(height: 20),
                MyTextfield(
                  controller: _phoneController,
                  icon: Icons.phone_android,
                  hintText: loc.translate('contactPhone'),
                ),
                SizedBox(height: 20),
              ],

              MyTextfield(
                controller: _emailController,
                icon: Icons.mail_outline,
                hintText: _isLogin
                    ? context.tr('emailOrPhone')
                    : 'Email (facultatif)',
              ),
              SizedBox(height: 20),
              MyTextfield(
                controller: _passwordController,
                icon: Icons.lock_outline,
                hintText: loc.translate('passwordHint'),
                obscureText: true,
              ),

              SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : MyButton(
                        icon: _isLogin ? Icons.login : Icons.how_to_reg,
                        text: _isLogin
                            ? loc.translate('connectButton')
                            : loc.translate('accountCreated'),
                        onTap: _isLogin ? _handleLogin : _handleRegister,
                      ),
              ),
              SizedBox(height: 18),
              if (_isLogin)
                Center(
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(context.tr('auto_mot_de_passe_oublie')),
                  ),
                ),
              Center(
                child: Text(
                  loc.translate('developerCredit'),
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: _toggleAuthMode,
                  child: Text(
                    _isLogin
                        ? loc.translate('createAccount')
                        : loc.translate('alreadyHaveAccount'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('loginCredentialsRequired'),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        final currentUser = result['user'] as AppUser;
        ApiService.setActiveUser(currentUser);
        await appLocale.loadForUser(currentUser.id);
        await AuthSessionService.saveSession(currentUser);
        await AuthSessionService.saveActiveSchool(null);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => SchoolSelectionPage(user: currentUser),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Connexion impossible',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.friendlyErrorMessage(e))),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.trim().isEmpty ||
        (_emailController.text.trim().isEmpty &&
            _phoneController.text.trim().isEmpty) ||
        _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('signupFormDescription'))),
      );
      return;
    }
    setState(() => _isLoading = true);
    final result = await ApiService.registerAccount(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final user = result['user'] as AppUser;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationPage(
            purpose: VerificationPurpose.registration,
            contact: _emailController.text.trim().isEmpty
                ? _phoneController.text.trim()
                : _emailController.text.trim(),
            userId: user.id,
            initialCode: result['verificationCode']?.toString(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Erreur lors de l\'inscription',
          ),
        ),
      );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final contactController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('forgotPassword')),
        content: MyTextfield(
          controller: contactController,
          icon: Icons.contact_mail,
          hintText: context.tr('emailOrPhone'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (contactController.text.trim().isEmpty) return;
              try {
                await ApiService.requestPasswordReset(
                  contactController.text.trim(),
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VerificationPage(
                      purpose: VerificationPurpose.passwordReset,
                      contact: contactController.text.trim(),
                    ),
                  ),
                );
              } catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(ApiService.friendlyErrorMessage(error)),
                    ),
                  );
                }
              }
            },
            child: Text('Envoyer le code'),
          ),
        ],
      ),
    );
    contactController.dispose();
  }
}
