import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../models/payment.dart';

class Paiements extends StatefulWidget {
  const Paiements({super.key});

  @override
  State<Paiements> createState() => _PaiementsState();
}

class _PaiementsState extends State<Paiements> {
  // Liste fictive basée sur le modèle Payment
  final List<Payment> _payments = [
    Payment(
      id: '1',
      studentId: '101',
      studentName: 'Moussa Diop',
      amount: 75000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      description: 'Frais de scolarité - 1ère Tranche',
    ),
    Payment(
      id: '2',
      studentId: '102',
      studentName: 'Awa Fall',
      amount: 50000,
      date: DateTime.now().subtract(const Duration(days: 2)),
      description: 'Frais d\'inscription',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header flexible
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            const Text(
              "Gestion Financière",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            MyButton(
              icon: Icons.add_card,
              text: "Enregistrer",
              onTap: () => _showAddPaymentDialog(),
            ),
          ],
        ),
        const SizedBox(height: 25),
        
        // Résumé financier flexible
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildFinanceCard("Encaissé", "1.2M", Colors.green),
            _buildFinanceCard("Impayés", "450k", Colors.red),
            _buildFinanceCard("Dépenses", "120k", Colors.orange),
          ],
        ),
        
        const SizedBox(height: 30),
        const Text("Derniers Paiements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _payments.length,
          itemBuilder: (context, index) {
            final payment = _payments[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: const Icon(Icons.arrow_upward, color: Colors.green, size: 18),
                ),
                title: Text(
                  payment.studentName, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(payment.description, style: const TextStyle(fontSize: 12)),
                trailing: Text(
                  "${payment.amount.toInt()} F",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFinanceCard(String title, String value, Color color) {
    return Container(
      width: 110, // Largeur fixe pour les cartes de stats sur mobile
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nouveau Paiement"),
        content: const Text("Formulaire de saisie en attente..."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer")),
        ],
      ),
    );
  }
}
