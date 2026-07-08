import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';

class GestionStaff extends StatefulWidget {
  final String currentUserRole;
  const GestionStaff({super.key, required this.currentUserRole});

  @override
  State<GestionStaff> createState() => _GestionStaffState();
}

class _GestionStaffState extends State<GestionStaff> {
  final List<Map<String, String>> _staffList = [
    {'nom': 'Dupont', 'prenom': 'Jean', 'role': 'Proviseur', 'email': 'j.dupont@edugest.com'},
    {'nom': 'Fall', 'prenom': 'Amadou', 'role': 'Censeur', 'email': 'a.fall@edugest.com'},
  ];

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = 'Censeur';

  void _showStaffDialog({int? index}) {
    if (index != null) {
      _nomController.text = _staffList[index]['nom']!;
      _prenomController.text = _staffList[index]['prenom']!;
      _emailController.text = _staffList[index]['email']!;
      _selectedRole = _staffList[index]['role']!;
    } else {
      _nomController.clear();
      _prenomController.clear();
      _emailController.clear();
      _selectedRole = 'Censeur';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(index == null ? "Ajouter un membre" : "Modifier le membre"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyTextfield(controller: _prenomController, hintText: "Prénom", icon: Icons.person_outline),
                const SizedBox(height: 16),
                MyTextfield(controller: _nomController, hintText: "Nom", icon: Icons.person),
                const SizedBox(height: 16),
                MyTextfield(controller: _emailController, hintText: "Email", icon: Icons.email_outlined),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: "Poste / Rôle",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: ['Proviseur', 'Censeur', 'Secrétaire', 'Comptable'].map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => _selectedRole = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                setState(() {
                  final data = {
                    'nom': _nomController.text,
                    'prenom': _prenomController.text,
                    'role': _selectedRole,
                    'email': _emailController.text,
                  };
                  if (index == null) {
                    _staffList.add(data);
                  } else {
                    _staffList[index] = data;
                  }
                });
                Navigator.pop(context);
              },
              child: Text(index == null ? "Créer" : "Mettre à jour", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Gestion du Personnel", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(
              width: 150,
              child: MyButton(icon: Icons.add, text: "Nouveau", onTap: () => _showStaffDialog()),
            ),
          ],
        ),
        const SizedBox(height: 25),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _staffList.length,
          itemBuilder: (context, index) {
            final staff = _staffList[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.admin_panel_settings)),
                title: Text("${staff['prenom']} ${staff['nom']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${staff['role']} • ${staff['email']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showStaffDialog(index: index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => _staffList.removeAt(index)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
