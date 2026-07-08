import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';

class Depenses extends StatelessWidget {
  const Depenses({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header flexible avec Wrap
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            const Text(
              "Gestion des Dépenses",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            MyButton(
              icon: Icons.add_shopping_cart,
              text: "Ajouter",
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Carte de résumé sécurisée avec LayoutBuilder
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red.withOpacity(0.1)),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Dépenses du mois", 
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "845,000 FCFA", 
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.trending_up, color: Colors.red, size: constraints.maxWidth > 300 ? 32 : 24),
              ],
            );
          }),
        ),
        const SizedBox(height: 32),
        const Text(
          "Dépenses récentes",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          itemBuilder: (context, index) {
            final items = [
              {'title': 'Facture Senelec', 'cat': 'Charges', 'price': '125,000'},
              {'title': 'Rames de papier', 'cat': 'Fournitures', 'price': '45,000'},
              {'title': 'Maintenance Informatique', 'cat': 'Services', 'price': '75,000'},
              {'title': 'Achat craies', 'cat': 'Fournitures', 'price': '12,000'},
            ];
            final item = items[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.bg,
                  child: const Icon(Icons.receipt_long, color: AppColors.textMuted, size: 18),
                ),
                title: Text(
                  item['title']!, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(item['cat']!, style: const TextStyle(fontSize: 12)),
                trailing: Text(
                  "${item['price']} F", 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
