import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';

class CahierTexte extends StatefulWidget {
  const CahierTexte({super.key});

  @override
  State<CahierTexte> createState() => _CahierTexteState();
}

class _CahierTexteState extends State<CahierTexte> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedClasse = 'Terminale S1';
  bool _isEditing = false;

  // Historique des leçons envoyées par cet enseignant
  final List<Map<String, String>> _myHistory = [
    {
      'date': '12/10/2023',
      'classe': 'Terminale S1',
      'matiere': 'Mathématiques',
      'titre': 'Dérivées et Continuité',
      'contenu': 'Introduction aux limites et continuité des fonctions numériques.'
    },
    {
      'date': '10/10/2023',
      'classe': '3ème A',
      'matiere': 'Mathématiques',
      'titre': 'Théorème de Thalès',
      'contenu': 'Application du théorème dans le triangle.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing ? "Modification de la Leçon" : "Cahier de Texte",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 20),

        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          onTap: (index) {
            if (index == 0 && !_isEditing) {
              setState(() {
                _titleController.clear();
                _contentController.clear();
              });
            }
            if (index == 0) setState(() => _isEditing = false);
          },
          tabs: const [
            Tab(text: "Saisie"),
            Tab(text: "Mes Publications"),
          ],
        ),
        
        const SizedBox(height: 25),

        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSaisieView(),
              _buildHistoryView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaisieView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange, size: 18),
                  SizedBox(width: 10),
                  Text("Mode Modification", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          const Text("Classe concernée", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
            child: DropdownButton<String>(
              value: _selectedClasse,
              isExpanded: true,
              underline: const SizedBox(),
              items: ['6ème A', '3ème A', 'Terminale S1'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedClasse = val!),
            ),
          ),
          const SizedBox(height: 20),
          MyTextfield(
            controller: _titleController,
            hintText: "Titre de la leçon",
            icon: Icons.title,
          ),
          const SizedBox(height: 20),
          const Text("Contenu détaillé", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Détaillez le cours ici...",
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: MyButton(
              icon: _isEditing ? Icons.update : Icons.send,
              text: _isEditing ? "Mettre à jour" : "Publier la leçon",
              onTap: () {
                setState(() => _isEditing = false);
                _titleController.clear();
                _contentController.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Leçon enregistrée avec succès !")));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return ListView.builder(
      itemCount: _myHistory.length,
      itemBuilder: (context, index) {
        final lecon = _myHistory[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            title: Text(lecon['titre']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("${lecon['classe']} • ${lecon['date']}"),
            trailing: IconButton(
              icon: const Icon(Icons.edit_note, color: AppColors.primary),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _selectedClasse = lecon['classe']!;
                  _titleController.text = lecon['titre']!;
                  _contentController.text = lecon['contenu']!;
                  _tabController.animateTo(0); 
                });
              },
            ),
          ),
        );
      },
    );
  }
}
