import 'package:edugest/components/app_colors.dart';
import 'package:edugest/components/my_button.dart';
import 'package:edugest/components/my_sidebar.dart';
import 'package:edugest/components/my_textfield.dart';
import 'package:edugest/components/responsive_layout.dart';
import 'package:edugest/pages/dashboard_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String selectedRole = 'Proviseur';

  final List<Map<String, dynamic>> roles = [
    {'name': 'Proviseur', 'icon': Icons.manage_accounts},
    {'name': 'Censeur', 'icon': Icons.assignment},
    {'name': 'Secrétaire', 'icon': Icons.folder_shared},
    {'name': 'Comptable', 'icon': Icons.account_balance_wallet},
    {'name': 'Enseignant', 'icon': Icons.school},
    {'name': 'Fondateur', 'icon': Icons.visibility},
  ];

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

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: isMobile ? Drawer(child: MySidebar(sections: _sidebarSections)) : null,
      appBar: isMobile
          ? AppBar(
              backgroundColor: AppColors.sidebarBg,
              title: const Text("Connexion", style: TextStyle(color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) MySidebar(sections: _sidebarSections),
          Expanded(child: _buildLoginForm(isMobile)),
        ],
      ),
    );
  }

  Widget _buildLoginForm(bool isMobile) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 25 : 100),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Se connecter",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.text),
              ),
              const SizedBox(height: 10),
              const Text(
                "Accédez à votre espace de gestion scolaire.",
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
              const SizedBox(height: 40),

              MyTextfield(
                controller: _emailController,
                icon: Icons.mail_outline,
                hintText: "Adresse email",
                obscureText: false,
              ),
              const SizedBox(height: 20),
              MyTextfield(
                controller: _passwordController,
                icon: Icons.lock_outline,
                hintText: "Mot de passe",
                obscureText: true,
              ),

              const SizedBox(height: 30),
              const Text("CHOISISSEZ VOTRE RÔLE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: roles.map((role) {
                  final bool isSelected = selectedRole == role['name'];
                  return GestureDetector(
                    onTap: () => setState(() => selectedRole = role['name']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(
                        role['name'],
                        style: TextStyle(color: isSelected ? Colors.white : AppColors.text, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: MyButton(
                  icon: Icons.login,
                  text: "Se connecter",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => DashboardPage(userRole: selectedRole)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
