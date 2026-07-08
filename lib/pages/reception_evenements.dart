import 'package:flutter/material.dart';
import '../components/app_colors.dart';

class ReceptionEvenements extends StatelessWidget {
  const ReceptionEvenements({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Annonces Administration",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 2,
          itemBuilder: (context, index) {
            final announcements = [
              {
                'title': 'Réunion de coordination',
                'from': 'Proviseur',
                'content': 'Tous les enseignants sont convoqués en salle de réunion demain à 15h.',
                'date': 'Aujourd\'hui'
              },
              {
                'title': 'Saisie des notes T1',
                'from': 'Censeur',
                'content': 'Le portail de saisie des notes fermera ce vendredi à minuit.',
                'date': 'Hier'
              },
            ];
            final item = announcements[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primaryPale, borderRadius: BorderRadius.circular(8)),
                        child: Text("Par : ${item['from']}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      Text(item['date']!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(item['title']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(item['content']!, style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.4)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
