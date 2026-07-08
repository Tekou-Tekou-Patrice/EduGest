import 'package:edugest/components/my_textfield.dart';
import 'package:edugest/models/teacher.dart'; // Import du modèle
import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';

class ListeEnseignant extends StatefulWidget {
  const ListeEnseignant({super.key});

  @override
  State<ListeEnseignant> createState() => _ListeEnseignantState();
}

class _ListeEnseignantState extends State<ListeEnseignant> {
  String selectedSubject = 'Tous';
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _tempSpeciality = 'Mathématiques';

  final List<String> subjects = [
    'Tous', 'Mathématiques', 'Français', 'Anglais', 'Physique-Chimie', 'SVT', 'Histoire-Géo', 'EPS'
  ];

  // Liste utilisant le modèle Teacher
  final List<Teacher> _allTeachers = [
    Teacher(id: 'T001', firstName: 'Amadou', lastName: 'Diallo', speciality: 'Mathématiques', email: 'a.diallo@edugest.com'),
    Teacher(id: 'T002', firstName: 'Fatoumata', lastName: 'Sow', speciality: 'Français', email: 'f.sow@edugest.com'),
  ];

  void _showTeacherDialog({int? index}) {
    if (index != null) {
      final t = _allTeachers[index];
      _nomController.text = t.lastName;
      _prenomController.text = t.firstName;
      _emailController.text = t.email ?? '';
      _phoneController.text = t.phone ?? '';
      _tempSpeciality = t.speciality;
    } else {
      _nomController.clear();
      _prenomController.clear();
      _emailController.clear();
      _phoneController.clear();
      _tempSpeciality = 'Mathématiques';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(index == null ? "Recruter un enseignant" : "Modifier l'enseignant"),
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
                MyTextfield(controller: _phoneController, hintText: "Téléphone", icon: Icons.phone_android),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _tempSpeciality,
                  decoration: InputDecoration(
                    labelText: "Spécialité",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: subjects.where((s) => s != 'Tous').map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => _tempSpeciality = val!),
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
                  final newTeacher = Teacher(
                    id: index == null ? 'T00${_allTeachers.length + 1}' : _allTeachers[index].id,
                    firstName: _prenomController.text,
                    lastName: _nomController.text,
                    speciality: _tempSpeciality,
                    email: _emailController.text,
                    phone: _phoneController.text,
                  );

                  if (index == null) {
                    _allTeachers.add(newTeacher);
                  } else {
                    _allTeachers[index] = newTeacher;
                  }
                });
                Navigator.pop(context);
              },
              child: Text(index == null ? "Recruter" : "Mettre à jour", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTeachers = _allTeachers.where((t) => selectedSubject == 'Tous' || t.speciality == selectedSubject).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Corps Enseignant", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(
              width: 150,
              child: MyButton(icon: Icons.person_add_alt_1, text: "Recruter", onTap: () => _showTeacherDialog()),
            ),
          ],
        ),
        const SizedBox(height: 20),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: subjects.map((subject) {
              final isSelected = selectedSubject == subject;
              return GestureDetector(
                onTap: () => setState(() => selectedSubject = subject),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(
                    subject,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 32),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredTeachers.length,
          itemBuilder: (context, index) {
            final teacher = filteredTeachers[index];
            final actualIndex = _allTeachers.indexOf(teacher);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryPale,
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                title: Text("${teacher.firstName} ${teacher.lastName}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Spécialité: ${teacher.speciality}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () => _showTeacherDialog(index: actualIndex),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => setState(() => _allTeachers.removeAt(actualIndex)),
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
