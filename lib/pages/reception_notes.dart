import 'package:flutter/material.dart';
import '../components/app_colors.dart';

class ReceptionNotes extends StatefulWidget {
  const ReceptionNotes({super.key});

  @override
  State<ReceptionNotes> createState() => _ReceptionNotesState();
}

class _ReceptionNotesState extends State<ReceptionNotes> {
  String selectedClasse = 'Terminale S1';
  String selectedSemestre = 'Semestre 1';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Réception des Notes",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildFilterLabel("Classe", selectedClasse, ['6ème A', '3ème A', 'Terminale S1'], (val) => setState(() => selectedClasse = val!)),
              _buildFilterLabel("Période", selectedSemestre, ['Semestre 1', 'Semestre 2'], (val) => setState(() => selectedSemestre = val!)),
            ],
          ),
        ),

        const SizedBox(height: 25),
        const Text("Soumissions reçues", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 2,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: const Icon(Icons.assignment_turned_in, color: AppColors.primary),
                title: Text(index == 0 ? "M. Diallo (Maths)" : "Mme. Sow (Anglais)", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("Envoyé le 12/10 • $selectedClasse"),
                trailing: const Icon(Icons.open_in_new, size: 20, color: AppColors.primary),
                onTap: () => _showGradesTable(context, index == 0 ? "M. Diallo" : "Mme. Sow"),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showGradesTable(BuildContext context, String prof) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Notes : $prof - $selectedClasse"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(AppColors.primaryPale),
                columns: const [
                  DataColumn(label: Text('Élève', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Note/20', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Observation', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: List.generate(8, (index) => DataRow(cells: [
                  DataCell(Text("Élève Nom ${index + 1}")),
                  DataCell(Text("${10 + index}.00")),
                  DataCell(Text(index < 5 ? "Admis" : "Échec", style: TextStyle(color: index < 5 ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                ])),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer")),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text("Valider", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildFilterLabel(String label, String value, List<String> items, Function(String?) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        DropdownButton<String>(
          value: value,
          isDense: true,
          underline: const SizedBox(),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChange,
        ),
      ],
    );
  }
}
