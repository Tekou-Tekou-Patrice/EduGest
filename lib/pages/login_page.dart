import 'package:edugest/components/app_colors.dart';
import 'package:edugest/components/my_button.dart';
import 'package:edugest/components/my_sidebar.dart';
import 'package:edugest/components/my_textfield.dart';
import 'package:edugest/components/responsive_layout.dart';
import 'package:edugest/localization/app_localizations.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/pages/school_selection_page.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/service/auth_session_service.dart';
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
        SidebarItem(icon: Icons.check, label: 'Gestion de notes'),
        SidebarItem(icon: Icons.check, label: 'Gestion de paiement'),
        SidebarItem(icon: Icons.check, label: 'Gestion de élèves'),
        SidebarItem(icon: Icons.check, label: 'Gestion de cours'),
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
                _isLogin ? loc.translate('loginTitle') : loc.translate('createAccount'),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
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
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isLogin ? loc.translate('loginTitle') : loc.translate('createAccount'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isLogin
                    ? loc.translate('loginSubtitle')
                    : loc.translate('signupDescription'),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),

              if (!_isLogin) ...[
                MyTextfield(
                  controller: _nameController,
                  icon: Icons.person,
                  hintText: loc.translate('fullNameHint'),
                ),
                const SizedBox(height: 20),
                MyTextfield(
                  controller: _phoneController,
                  icon: Icons.phone_android,
                  hintText: loc.translate('contactPhone'),
                ),
                const SizedBox(height: 20),
              ],

              MyTextfield(
                controller: _emailController,
                icon: Icons.mail_outline,
                hintText: loc.translate('emailHint'),
              ),
              const SizedBox(height: 20),
              MyTextfield(
                controller: _passwordController,
                icon: Icons.lock_outline,
                hintText: loc.translate('passwordHint'),
                obscureText: true,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : MyButton(
                        icon: _isLogin ? Icons.login : Icons.how_to_reg,
                        text: _isLogin
                            ? loc.translate('connectButton')
                            : loc.translate('accountCreated'),
                        onTap: _isLogin ? _handleLogin : _handleRegister,
                      ),
              ),
              const SizedBox(height: 18),
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

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: _toggleAuthMode,
                  child: Text(
                    _isLogin
                        ? loc.translate('createAccount')
                        : loc.translate('alreadyHaveAccount'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(ApiService.friendlyErrorMessage(e))),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Renseignez votre nom, un email valide et un mot de passe de 6 caractères minimum.',
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final result = await ApiService.registerAccount(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Compte créé avec succès ! Connectez-vous."),
        ),
      );
      setState(() => _isLogin = true);
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
}
