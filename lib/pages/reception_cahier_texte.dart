import 'package:flutter/material.dart';
import '../components/app_colors.dart';

class ReceptionCahierTexte extends StatefulWidget {
  const ReceptionCahierTexte({super.key});

  @override
  State<ReceptionCahierTexte> createState() => _ReceptionCahierTexteState();
}

class _ReceptionCahierTexteState extends State<ReceptionCahierTexte> {
  String selectedClasse = 'Terminale S1';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Suivi des Cahiers de Texte",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 20),

        // Filtre par classe
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(10), 
            border: Border.all(color: AppColors.border)
          ),
          child: DropdownButton<String>(
            value: selectedClasse,
            isExpanded: true,
            underline: const SizedBox(),
            items: ['6ème A', '3ème A', 'Terminale S1'].map((c) => DropdownMenuItem(value: c, child: Text("Classe : $c"))).toList(),
            onChanged: (val) => setState(() => selectedClasse = val!),
          ),
        ),

        const SizedBox(height: 25),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 2,
          itemBuilder: (context, index) {
            final lessons = [
              {'prof': 'M. Diallo', 'matiere': 'Mathématiques', 'titre': 'Les Intégrales', 'date': 'Aujourd\'hui'},
              {'prof': 'Mme. Sow', 'matiere': 'Anglais', 'titre': 'Business English', 'date': 'Hier'},
            ];
            final item = lessons[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['prof']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(item['date']!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("${item['matiere']} • $selectedClasse", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text(
                    "Titre : ${item['titre']}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Résumé : Application des méthodes d'intégration par parties et exercices pratiques en classe.",
                    style: TextStyle(fontSize: 13, color: AppColors.text),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
