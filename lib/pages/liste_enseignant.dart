import 'package:edugest/components/my_textfield.dart';
import 'package:edugest/models/teacher.dart';
import 'package:edugest/models/subject.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';

class ListeEnseignant extends StatefulWidget {
  const ListeEnseignant({super.key});

  @override
  State<ListeEnseignant> createState() => _ListeEnseignantState();
}

class _ListeEnseignantState extends State<ListeEnseignant> {
  String selectedSubjectName = 'Tous';
  String searchQuery = "";
  List<Teacher> _allTeachers = [];
  List<Subject> _availableSubjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _fetchSubjects();
    await _fetchTeachers();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchSubjects() async {
    try {
      final data = await ApiService.getSubjects();
      setState(() {
        _availableSubjects = data;
      });
    } catch (e) {
      debugPrint("Erreur chargement matières: $e");
    }
  }

  Future<void> _fetchTeachers() async {
    try {
      final data = await ApiService.getTeachers(query: searchQuery.isEmpty ? null : searchQuery);
      setState(() {
        _allTeachers = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du chargement des enseignants")),
      );
    }
  }

  void _showTeacherDialog({Teacher? teacher}) {
    final nomController = TextEditingController(text: teacher?.lastName ?? '');
    final prenomController = TextEditingController(text: teacher?.firstName ?? '');
    final emailController = TextEditingController(text: teacher?.email ?? '');
    final passwordController = TextEditingController();
    String? selectedSpec = teacher?.speciality;
    
    // Si la spécialité du prof n'est pas dans la liste (ex: nouvelle base), on reset
    if (selectedSpec != null && !_availableSubjects.any((s) => s.name == selectedSpec)) {
      selectedSpec = null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(teacher == null ? "Recruter Enseignant" : "Modifier Enseignant"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyTextfield(controller: prenomController, hintText: "Prénom", icon: Icons.person_outline),
                const SizedBox(height: 16),
                MyTextfield(controller: nomController, hintText: "Nom", icon: Icons.person),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSpec,
                  hint: const Text("Spécialité (Matière)"),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.book, color: AppColors.primary),
                  ),
                  items: _availableSubjects.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))).toList(),
                  onChanged: (val) => setDialogState(() => selectedSpec = val),
                ),
                const SizedBox(height: 16),
                MyTextfield(controller: emailController, hintText: "Email (Identifiant)", icon: Icons.email_outlined),
                if (teacher == null) ...[
                  const SizedBox(height: 16),
                  MyTextfield(
                    controller: passwordController,
                    hintText: "Mot de passe temporaire",
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (prenomController.text.isEmpty || nomController.text.isEmpty || emailController.text.isEmpty || selectedSpec == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Veuillez remplir tous les champs")),
                  );
                  return;
                }

                final newTeacher = Teacher(
                  id: teacher?.id ?? '',
                  firstName: prenomController.text.trim(),
                  lastName: nomController.text.trim(),
                  speciality: selectedSpec!,
                  email: emailController.text.trim(),
                  password: passwordController.text.isNotEmpty ? passwordController.text : null,
                );
                
                await ApiService.saveTeacher(newTeacher);
                _fetchTeachers();
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Valider", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTeachers = _allTeachers.where((t) => selectedSubjectName == 'Tous' || t.speciality == selectedSubjectName).toList();
    final filterTabs = ['Tous', ..._availableSubjects.map((s) => s.name)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16, runSpacing: 10,
          children: [
            const Text("Corps Enseignant", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            MyButton(icon: Icons.person_add_alt_1, text: "Recruter", onTap: () => _showTeacherDialog()),
          ],
        ),
        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            onChanged: (val) {
              searchQuery = val;
              _fetchTeachers();
            },
            decoration: const InputDecoration(
              hintText: "Rechercher un professeur...",
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        const SizedBox(height: 20),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filterTabs.map((subjectName) {
              final isSelected = selectedSubjectName == subjectName;
              return GestureDetector(
                onTap: () => setState(() => selectedSubjectName = subjectName),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(
                    subjectName,
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

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (filteredTeachers.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Aucun enseignant trouvé.")))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredTeachers.length,
            itemBuilder: (context, index) {
              final teacher = filteredTeachers[index];
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
                  subtitle: Text("Spécialité: ${teacher.speciality} | ${teacher.email ?? ''}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () => _showTeacherDialog(teacher: teacher),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () async {
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Supprimer"),
                              content: const Text("Voulez-vous vraiment supprimer cet enseignant et son compte ?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Non")),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Oui")),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ApiService.deleteTeacher(teacher.id);
                            _fetchTeachers();
                          }
                        },
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
