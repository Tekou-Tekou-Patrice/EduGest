import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';

class Notes extends StatefulWidget {
  const Notes({super.key});

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedClasse = '6eme';
  String selectedSequence = 'Séquence 1';
  bool _isEditing = false; 

  final List<String> classes = ['6eme', '5eme', '4eme', '3eme', '2nd', '1ere', 'Terminale'];
  final List<String> sequences = ['Séquence 1', 'Séquence 2', 'Séquence 3'];

  // Simulation d'une base de données d'élèves par classe
  final List<Map<String, dynamic>> _allStudents = [
    {'name': 'Moussa Diop', 'classe': '6eme', 'grade': '14'},
    {'name': 'Awa Fall', 'classe': '6eme', 'grade': '16'},
    {'name': 'Oumar Ndiaye', 'classe': '5eme', 'grade': '12'},
    {'name': 'Fatou Sow', 'classe': '5eme', 'grade': '15'},
    {'name': 'Jean Gomis', 'classe': 'Terminale', 'grade': '11'},
    {'name': 'Mariam Ba', 'classe': 'Terminale', 'grade': '17'},
  ];

  // Historique des envois
  final List<Map<String, dynamic>> _history = [
    {'classe': '6eme', 'seq': 'Séquence 1', 'date': '10 Oct 2023', 'status': 'Validé', 'color': Colors.green},
    {'classe': '5eme', 'seq': 'Séquence 1', 'date': '12 Oct 2023', 'status': 'En attente', 'color': Colors.orange},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _currentStudents => 
      _allStudents.where((s) => s['classe'] == selectedClasse).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing ? "Modification des Notes" : "Gestion des Notes", 
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)
        ),
        const SizedBox(height: 20),
        
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          onTap: (index) {
            if (index == 0) setState(() => _isEditing = false);
          },
          tabs: const [
            Tab(text: "Saisie"),
            Tab(text: "Mes Envois"),
          ],
        ),
        
        const SizedBox(height: 25),
        
        Expanded(
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
    final studentsList = _currentStudents;

    return SingleChildScrollView(
      child: Column(
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
                  Text("Mode Modification activé", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          _buildFilters(),
          const SizedBox(height: 20),
          
          if (studentsList.isEmpty)
            const Padding(padding: EdgeInsets.all(20.0), child: Text("Aucun élève trouvé."))
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: studentsList.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) => ListTile(
                  title: Text(studentsList[index]['name'], style: const TextStyle(fontSize: 14)),
                  trailing: SizedBox(
                    width: 70,
                    child: TextField(
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: studentsList[index]['grade'],
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: MyButton(
              icon: _isEditing ? Icons.update : Icons.send, 
              text: _isEditing ? "Mettre à jour l'envoi" : "Envoyer à l'administration", 
              onTap: () {
                setState(() => _isEditing = false);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opération réussie !")));
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            title: Text("${item['classe']} - ${item['seq']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Envoyé le ${item['date']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: item['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(item['status'], style: TextStyle(color: item['color'], fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_note, color: AppColors.primary),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      selectedClasse = item['classe'];
                      selectedSequence = item['seq'];
                      _tabController.animateTo(0); 
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildDropdown("Classe", selectedClasse, classes, (v) => setState(() => selectedClasse = v!)),
        _buildDropdown("Séquence", selectedSequence, sequences, (v) => setState(() => selectedSequence = v!)),
      ],
    );
  }

  Widget _buildDropdown(String label, String val, List<String> items, Function(String?) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
          child: DropdownButton<String>(
            value: val,
            isDense: true,
            underline: const SizedBox(),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: onChange,
          ),
        ),
      ],
    );
  }
}
