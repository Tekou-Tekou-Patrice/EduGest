import 'package:edugest/components/my_textfield.dart';
import 'package:edugest/models/student.dart'; // Import du modèle
import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';

class ListeEleves extends StatefulWidget {
  const ListeEleves({super.key});

  @override
  State<ListeEleves> createState() => _ListeElevesState();
}

class _ListeElevesState extends State<ListeEleves> {
  String selectedClasse = '6eme';
  String searchQuery = "";
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();

  final List<String> classes = ['6eme', '5eme', '4eme', '3eme', '2nd', '1ere', 'Terminale'];

  // Liste utilisant le modèle Student
  final List<Student> _allEleves = [
    Student(id: '2024-001', firstName: 'Moussa', lastName: 'Diop', className: '6eme'),
    Student(id: '2024-002', firstName: 'Awa', lastName: 'Fall', className: '6eme'),
    Student(id: '2024-003', firstName: 'Oumar', lastName: 'Ndiaye', className: '5eme'),
  ];

  List<Student> get _filteredEleves {
    return _allEleves.where((eleve) {
      final matchesClasse = eleve.className == selectedClasse;
      final matchesSearch = eleve.lastName.toLowerCase().contains(searchQuery.toLowerCase()) || 
                           eleve.firstName.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesClasse && matchesSearch;
    }).toList();
  }

  void _showStudentDialog({int? index}) {
    if (index != null) {
      _nomController.text = _allEleves[index].lastName;
      _prenomController.text = _allEleves[index].firstName;
    } else {
      _nomController.clear();
      _prenomController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? "Inscrire un élève" : "Modifier l'élève"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyTextfield(controller: _prenomController, hintText: "Prénom", icon: Icons.person_outline),
            const SizedBox(height: 16),
            MyTextfield(controller: _nomController, hintText: "Nom", icon: Icons.person),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              setState(() {
                if (index == null) {
                  _allEleves.add(Student(
                    id: '2024-0${_allEleves.length + 1}',
                    firstName: _prenomController.text,
                    lastName: _nomController.text,
                    className: selectedClasse,
                  ));
                } else {
                  _allEleves[index] = Student(
                    id: _allEleves[index].id,
                    firstName: _prenomController.text,
                    lastName: _nomController.text,
                    className: _allEleves[index].className,
                  );
                }
              });
              Navigator.pop(context);
            },
            child: Text(index == null ? "Inscrire" : "Mettre à jour", style: const TextStyle(color: Colors.white)),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Gestion des Élèves", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(width: 140, child: MyButton(icon: Icons.person_add, text: "Ajouter", onTap: () => _showStudentDialog())),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (val) => setState(() => searchQuery = val),
          decoration: InputDecoration(
            hintText: "Rechercher...",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: classes.map((c) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(c),
                selected: selectedClasse == c,
                onSelected: (s) => setState(() => selectedClasse = c),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredEleves.length,
          itemBuilder: (context, index) {
            final eleve = _filteredEleves[index];
            final actualIndex = _allEleves.indexOf(eleve);
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text("${eleve.firstName} ${eleve.lastName}"),
                subtitle: Text("ID: ${eleve.id}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _showStudentDialog(index: actualIndex)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => setState(() => _allEleves.removeAt(actualIndex))),
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
