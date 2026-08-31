import 'package:edugest/models/student.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/models/school_class.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/components/my_textfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';

class ListeEleves extends StatefulWidget {
  final AppUser currentUser;
  const ListeEleves({super.key, required this.currentUser});

  @override
  State<ListeEleves> createState() => _ListeElevesState();
}

class _ListeElevesState extends State<ListeEleves> {
  String selectedClasse = 'Toutes';
  String searchQuery = "";
  List<Student> _eleves = [];
  List<SchoolClass> _availableClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _fetchClasses();
    await _fetchData();
  }

  Future<void> _fetchClasses() async {
    try {
      final data = await ApiService.getClassrooms();
      if (mounted) {
        setState(() {
          _availableClasses = data;
        });
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des classes: $e");
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getStudents(
        className: selectedClasse == 'Toutes' ? null : selectedClasse,
        query: searchQuery.isEmpty ? null : searchQuery,
      );
      if (mounted) {
        setState(() {
          _eleves = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showStudentDialog({Student? student}) {
    final prenomCtrl = TextEditingController(text: student?.firstName ?? '');
    final nomCtrl = TextEditingController(text: student?.lastName ?? '');
    final parentNomCtrl = TextEditingController(text: student?.parentName ?? '');
    final parentPhoneCtrl = TextEditingController(text: student?.parentPhone ?? '');
    final parentEmailCtrl = TextEditingController(text: student?.parentEmail ?? '');
    final parentPasswordCtrl = TextEditingController();
    
    DateTime? selectedBirthDate = student?.birthDate;
    final birthDateCtrl = TextEditingController(
      text: selectedBirthDate != null ? DateFormat('dd/MM/yyyy').format(selectedBirthDate!) : ''
    );
    
    String? currentClass = student?.className;
    if (currentClass == null || currentClass.isEmpty) {
      if (selectedClasse != 'Toutes') {
        currentClass = selectedClasse;
      } else if (_availableClasses.isNotEmpty) {
        currentClass = _availableClasses.first.name;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(student == null ? "Inscrire un Élève" : "Modifier l'Élève"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Informations Élève", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                MyTextfield(controller: prenomCtrl, hintText: "Prénom", icon: Icons.person_outline),
                const SizedBox(height: 12),
                MyTextfield(controller: nomCtrl, hintText: "Nom", icon: Icons.person),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedBirthDate ?? DateTime(2010),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedBirthDate = picked;
                        birthDateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: MyTextfield(
                      controller: birthDateCtrl,
                      hintText: "Date de naissance",
                      icon: Icons.calendar_today,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _availableClasses.any((c) => c.name == currentClass) ? currentClass : null,
                  hint: const Text("Sélectionner une classe"),
                  decoration: InputDecoration(
                    labelText: "Classe",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _availableClasses
                      .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => currentClass = val);
                  },
                ),
                
                const SizedBox(height: 24),
                const Text("Informations Parent", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                MyTextfield(controller: parentNomCtrl, hintText: "Nom du Parent", icon: Icons.family_restroom),
                const SizedBox(height: 12),
                MyTextfield(controller: parentPhoneCtrl, hintText: "Téléphone du Parent", icon: Icons.phone_callback),
                const SizedBox(height: 12),
                MyTextfield(controller: parentEmailCtrl, hintText: "Email du Parent", icon: Icons.email_outlined),
                const SizedBox(height: 12),
                if (student == null)
                  MyTextfield(
                    controller: parentPasswordCtrl,
                    hintText: "Mot de passe temporaire du Parent (facultatif)",
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                if (student == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      "Si laissé vide, le numéro du parent sera utilisé comme mot de passe temporaire.",
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                
                if (_availableClasses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text("Aucune classe disponible. Créez-en une d'abord.", 
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
          ),
          actions: [
            if (student != null)
              TextButton(
                onPressed: () async {
                  await ApiService.deleteStudent(student.id);
                  if (mounted) Navigator.pop(context);
                  _fetchData();
                },
                child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (prenomCtrl.text.trim().isEmpty || nomCtrl.text.trim().isEmpty || currentClass == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Veuillez remplir le nom, prénom et choisir une classe"))
                  );
                  return;
                }
                final newStudent = Student(
                  id: student?.id ?? '',
                  firstName: prenomCtrl.text.trim(),
                  lastName: nomCtrl.text.trim(),
                  className: currentClass!,
                  birthDate: selectedBirthDate,
                  parentName: parentNomCtrl.text.trim(),
                  parentPhone: parentPhoneCtrl.text.trim(),
                  parentEmail: parentEmailCtrl.text.trim(),
                  parentPassword: parentPasswordCtrl.text,
                  registeredById: widget.currentUser.id,
                );
                await ApiService.saveStudent(newStudent);
                if (mounted) Navigator.pop(context);
                _fetchData();
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
    final allFilterClasses = ['Toutes', ..._availableClasses.map((e) => e.name)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            const Text("Gestion des Élèves", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showStudentDialog(),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                MyButton(icon: Icons.refresh, text: "Actualiser", onTap: _loadInitialData),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: TextField(
            onChanged: (val) {
              searchQuery = val;
              _fetchData();
            },
            decoration: const InputDecoration(hintText: "Rechercher un élève...", icon: Icon(Icons.search), border: InputBorder.none),
          ),
        ),
        const SizedBox(height: 20),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: allFilterClasses.map((c) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(c),
                selected: selectedClasse == c,
                onSelected: (s) {
                  setState(() => selectedClasse = c);
                  _fetchData();
                },
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 25),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_eleves.isEmpty)
          const Center(child: Text("Aucun élève trouvé."))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _eleves.length,
            itemBuilder: (context, index) {
              final student = _eleves[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.border)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryPale,
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text("${student.firstName} ${student.lastName}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Classe: ${student.className}"),
                      if (student.birthDate != null)
                        Text("Né(e) le: ${DateFormat('dd/MM/yyyy').format(student.birthDate!)}", style: const TextStyle(fontSize: 12)),
                      if (student.parentName != null && student.parentName!.isNotEmpty)
                        Text("Parent: ${student.parentName} (${student.parentPhone ?? ''})", style: const TextStyle(fontSize: 12)),
                      if (student.registeredByName != null)
                        Text("Inscrit par: ${student.registeredByName}", style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    onPressed: () => _showStudentDialog(student: student),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
