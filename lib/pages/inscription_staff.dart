import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../service/api_service.dart';

class InscriptionStaff extends StatefulWidget {
  const InscriptionStaff({super.key});

  @override
  State<InscriptionStaff> createState() => _InscriptionStaffState();
}

class _InscriptionStaffState extends State<InscriptionStaff> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String _selectedRole = 'Proviseur';
  final List<String> _roles = ['Proviseur', 'Censeur', 'Secrétaire', 'Comptable'];
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir les champs obligatoires")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Appel au service API (à brancher sur ton backend Java)
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
            SnackBar(content: Text("Compte $_selectedRole créé avec succès !")),
          );
          _clearForm();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? "Erreur lors de l'inscription")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Une erreur réseau est survenue")),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Inscription du Personnel Administratif",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const Text(
          "Créez les comptes officiels pour la direction et la gestion.",
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
              const Text("Informations Personnelles", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
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
              const SizedBox(height: 24),
              const Text("Identifiants de connexion", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              MyTextfield(
                controller: _emailController,
                hintText: "Adresse email professionnelle",
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
              const Text("Attribution du Poste", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
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
                      icon: Icons.how_to_reg,
                      text: "Inscrire le membre du staff",
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
