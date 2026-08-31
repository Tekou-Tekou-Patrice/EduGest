import 'package:edugest/components/my_button.dart';
import 'package:edugest/components/my_textfield.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../models/app_user.dart';

class Profil extends StatelessWidget {
  final AppUser user;
  const Profil({super.key, required this.user});

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Changer le mot de passe"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyTextfield(
              controller: oldPasswordController,
              hintText: "Ancien mot de passe",
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            MyTextfield(
              controller: newPasswordController,
              hintText: "Nouveau mot de passe",
              icon: Icons.lock_reset,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            MyTextfield(
              controller: confirmPasswordController,
              hintText: "Confirmer le mot de passe",
              icon: Icons.lock_reset,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (oldPasswordController.text.isEmpty ||
                  newPasswordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Veuillez remplir tous les champs")),
                );
                return;
              }
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Les mots de passe ne correspondent pas")),
                );
                return;
              }

              try {
                await ApiService.changePassword(
                  userId: user.id,
                  oldPassword: oldPasswordController.text,
                  newPassword: newPasswordController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Mot de passe modifié avec succès")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text("Valider", style: TextStyle(color: Colors.white)),
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
        const Text(
          "Mon Profil",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
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
                child: Text(user.initials, style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.displayRole,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        _buildSectionTitle("Informations personnelles"),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.email_outlined, "Email", user.email),
              const Divider(height: 24),
              _buildInfoRow(Icons.person_outline, "Utilisateur", user.name),
              const Divider(height: 24),
              _buildInfoRow(Icons.badge_outlined, "Rôle", user.displayRole),
            ],
          ),
        ),

        const SizedBox(height: 32),
        _buildSectionTitle("Sécurité"),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: MyButton(
            icon: Icons.lock_reset,
            text: "Changer le mot de passe",
            onTap: () => _showChangePasswordDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
