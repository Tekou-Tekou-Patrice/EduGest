import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../models/subject.dart';
import '../service/api_service.dart';

class GestionMatieres extends StatefulWidget {
  const GestionMatieres({super.key});

  @override
  State<GestionMatieres> createState() => _GestionMatieresState();
}

class _GestionMatieresState extends State<GestionMatieres> {
  List<Subject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getSubjects();
      if (mounted) {
        setState(() {
          _subjects = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors du chargement des matières")),
        );
      }
    }
  }

  void _showSubjectDialog({Subject? subject}) {
    final nameCtrl = TextEditingController(text: subject?.name ?? '');
    final coeffCtrl = TextEditingController(text: subject?.coefficient.toString() ?? '1.0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(subject == null ? "Ajouter une matière" : "Modifier la matière"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyTextfield(
                controller: nameCtrl,
                hintText: "Nom de la matière (ex: Mathématiques)",
                icon: Icons.book_outlined,
              ),
              const SizedBox(height: 16),
              MyTextfield(
                controller: coeffCtrl,
                hintText: "Coefficient",
                icon: Icons.star_outline,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              
              final newSubject = Subject(
                id: subject?.id ?? '',
                name: nameCtrl.text.trim(),
                coefficient: double.tryParse(coeffCtrl.text) ?? 1.0,
              );

              try {
                await ApiService.saveSubject(newSubject);
                if (mounted) {
                  Navigator.pop(context);
                  _fetchSubjects();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Erreur lors de l'enregistrement")),
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
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            const Text(
              "Gestion des Matières",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            MyButton(
              icon: Icons.add,
              text: "Ajouter Matière",
              onTap: () => _showSubjectDialog(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_subjects.isEmpty)
          const Center(child: Text("Aucune matière enregistrée."))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _subjects.length,
            itemBuilder: (context, index) {
              final s = _subjects[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryPale,
                    child: Icon(Icons.book, color: AppColors.primary),
                  ),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Coefficient: ${s.coefficient}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                        onPressed: () => _showSubjectDialog(subject: s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Supprimer"),
                              content: Text("Voulez-vous vraiment supprimer la matière ${s.name} ?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Non")),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Oui")),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ApiService.deleteSubject(s.id);
                            _fetchSubjects();
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
