import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../service/api_service.dart';

class InscriptionStaff extends StatefulWidget {
  final VoidCallback? onSuccess;
  const InscriptionStaff({super.key, this.onSuccess});

  @override
  State<InscriptionStaff> createState() => _InscriptionStaffState();
}

class _InscriptionStaffState extends State<InscriptionStaff> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String _selectedRole = 'Proviseur';
  final List<String> _roles = [
    'Proviseur', 
    'Censeur', 
    'Surveillant Général', 
    'Secrétaire', 
    'Comptable', 
    'Enseignant'
  ];
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs obligatoires")),
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
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Le compte $_selectedRole a été créé avec succès !")),
          );
          _clearForm();
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? "Erreur lors de la création")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur de connexion au serveur")),
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
    setState(() => _selectedRole = 'Proviseur');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Inscription du Personnel",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 8),
        const Text(
          "Créez les accès pour les membres de votre administration.",
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 30),
        
        Container(
          padding: const EdgeInsets.all(24),
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
                hintText: "Nom complet",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              MyTextfield(
                controller: _phoneController,
                hintText: "Téléphone",
                icon: Icons.phone_android,
              ),
              const SizedBox(height: 16),
              MyTextfield(
                controller: _emailController,
                hintText: "Email professionnel (Identifiant)",
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              MyTextfield(
                controller: _passwordController,
                hintText: "Mot de passe temporaire",
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              const Text("Poste attribué", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.admin_panel_settings, color: AppColors.primary),
                ),
                items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 40),
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: MyButton(
                      icon: Icons.person_add_alt_1,
                      text: "Créer le compte staff",
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
