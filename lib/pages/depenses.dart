import 'package:edugest/models/app_user.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';

class Depenses extends StatefulWidget {
  final AppUser currentUser;
  const Depenses({super.key, required this.currentUser});

  @override
  State<Depenses> createState() => _DepensesState();
}

class _DepensesState extends State<Depenses> {
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getExpenses();
      if (!mounted) return;
      setState(() {
        _expenses = data;
        _total = data.fold(0.0, (sum, e) {
          final amount = e['amount'];
          if (amount is num) return sum + amount.toDouble();
          return sum + (double.tryParse('$amount') ?? 0);
        });
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du chargement des dépenses")),
      );
    }
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Charges';
    final categories = ['Charges', 'Fournitures', 'Services', 'Achat', 'Autre'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Nouvelle dépense"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyTextfield(controller: titleCtrl, hintText: "Libellé", icon: Icons.receipt),
                const SizedBox(height: 12),
                MyTextfield(controller: amountCtrl, hintText: "Montant", icon: Icons.payments),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: InputDecoration(
                    labelText: "Catégorie",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 12),
                MyTextfield(controller: descCtrl, hintText: "Description (optionnel)", icon: Icons.notes),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                if (titleCtrl.text.isEmpty || amount == null) return;
                try {
                  await ApiService.saveExpense({
                    'title': titleCtrl.text.trim(),
                    'category': category,
                    'amount': amount,
                    'date': DateTime.now().toIso8601String(),
                    'description': descCtrl.text.trim(),
                    'recordedById': widget.currentUser.id,
                  });
                  if (context.mounted) Navigator.pop(context);
                  await _fetchExpenses();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Erreur d'enregistrement")),
                    );
                  }
                }
              },
              child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            const Text("Gestion des Dépenses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            MyButton(icon: Icons.add_shopping_cart, text: "Ajouter", onTap: _showAddDialog),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.orange),
              const SizedBox(width: 12),
              Text(
                "Total dépenses : ${_total.toStringAsFixed(0)} FCFA",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_expenses.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Aucune dépense enregistrée")))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _expenses.length,
            itemBuilder: (context, index) {
              final item = _expenses[index];
              final amount = item['amount'];
              final amountLabel = amount is num
                  ? amount.toStringAsFixed(0)
                  : amount?.toString() ?? '0';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                  title: Text(item['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${item['category'] ?? ''} • ${_formatDate(item['date'])}"),
                      if (item['recordedByName'] != null)
                        Text("Effectuée par: ${item['recordedByName']}", style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("-$amountLabel F", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () async {
                          try {
                            await ApiService.deleteExpense(item['id'].toString());
                            await _fetchExpenses();
                          } catch (_) {}
                        },
                      ),
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
