import 'package:flutter/material.dart';
import '../components/app_colors.dart';

class EmploiDuTemps extends StatefulWidget {
  const EmploiDuTemps({super.key});

  @override
  State<EmploiDuTemps> createState() => _EmploiDuTempsState();
}

class _EmploiDuTempsState extends State<EmploiDuTemps> {
  String selectedDay = 'Lundi';
  final List<String> days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

  // Données de test
  final List<Map<String, dynamic>> schedule = [
    {'time': '08:00 - 10:00', 'subject': 'Mathématiques', 'class': 'Terminale S1', 'teacher': 'M. Diallo', 'color': Colors.blue},
    {'time': '10:00 - 12:00', 'subject': 'Français', 'class': '1ère L2', 'teacher': 'Mme. Sow', 'color': Colors.orange},
    {'time': '12:00 - 13:00', 'subject': 'PAUSE DÉJEUNER', 'isBreak': true, 'color': Colors.grey},
    {'time': '13:00 - 15:00', 'subject': 'Physique', 'class': '2nde S', 'teacher': 'M. Ndiaye', 'color': Colors.purple},
    {'time': '15:00 - 17:00', 'subject': 'Anglais', 'class': '3ème A', 'teacher': 'Mme. Fall', 'color': Colors.green},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Planning Hebdomadaire",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 20),

        // Sélecteur de jour
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: days.map((day) {
              final isSelected = selectedDay == day;
              return GestureDetector(
                onTap: () => setState(() => selectedDay = day),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 30),

        // Liste des cours
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: schedule.length,
          itemBuilder: (context, index) {
            final item = schedule[index];
            final bool isBreak = item['isBreak'] ?? false;

            return IntrinsicHeight(
              child: Row(
                children: [
                  // Heure
                  SizedBox(
                    width: 80,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item['time'].split(' - ')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
                        Text(item['time'].split(' - ')[1], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),

                  // Ligne
                  const VerticalDivider(thickness: 2, color: AppColors.border),

                  // Carte du cours
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isBreak ? Colors.grey.shade100 : (item['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isBreak ? Colors.grey.shade300 : (item['color'] as Color).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['subject'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isBreak ? Colors.grey.shade600 : item['color'],
                            ),
                          ),
                          if (!isBreak) ...[
                            const SizedBox(height: 5),
                            Text("${item['class']} • ${item['teacher']}", 
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ],
                      ),
                    ),
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
